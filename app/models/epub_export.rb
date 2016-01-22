class EpubExport < ActiveRecord::Base
  include CC::Exporter::Epub::Exportable
  include Workflow

  belongs_to :content_export
  belongs_to :course
  belongs_to :user
  has_many :attachments, -> { order('created_at DESC') }, dependent: :destroy, as: :context, class_name: 'Attachment'
  has_one :epub_attachment, -> { where(content_type: 'application/epub+zip').order('created_at DESC') }, as: :context, class_name: 'Attachment'
  has_one :zip_attachment, -> { where(content_type: 'application/zip').order('created_at DESC') }, as: :context, class_name: 'Attachment'
  has_one :job_progress, as: :context, class_name: 'Progress'
  validates :course_id, :workflow_state, presence: true

  PERCENTAGE_COMPLETE = {
    created: 0,
    exporting: 25,
    exported: 50,
    generating: 75,
    generated: 100
  }.freeze

  workflow do         # percentage completion
    state :created    # 0%
    state :exporting  # 25%
    state :exported   # 50%
    state :generating # 75%
    state :generated  # 100%
    state :failed
    state :deleted
  end

  after_create do
    create_job_progress(completion: 0, tag: 'epub_export')
  end

  delegate :download_url, to: :attachment, allow_nil: true
  delegate :completion, :running?, to: :job_progress, allow_nil: true

  scope :running, -> { where(workflow_state: ['created', 'exporting', 'exported', 'generating']) }
  scope :visible_to, ->(user) { where(user_id: user) }

  set_policy do
    given do |user|
      course.grants_right?(user, :read_as_admin) ||
        course.grants_right?(user, :participate_as_student)
    end
    can :create

    given do |user|
      self.user == user || course.grants_right?(user, :read_as_admin)
    end
    can :read

    given do |user|
      grants_right?(user, :read) && generated?
    end
    can :download

    given do |user|
      [ 'generated', 'failed' ].include?(workflow_state) &&
        self.grants_right?(user, :create)
    end
    can :regenerate
  end

  def export
    create_content_export!({
      user: user,
      export_type: ContentExport::COMMON_CARTRIDGE,
      selected_content: { :everything => true },
      progress: 0,
      context: course
    })
    job_progress.completion = PERCENTAGE_COMPLETE[:exporting]
    job_progress.start
    update_attribute(:workflow_state, 'exporting')
    content_export.export
    true
  end
  handle_asynchronously :export, priority: Delayed::LOW_PRIORITY, max_attempts: 1

  def mark_exported
    if content_export.failed?
      mark_as_failed
    else
      update_attribute(:workflow_state, 'exported')
      job_progress.update_attribute(:completion, PERCENTAGE_COMPLETE[:exported])
      generate
    end
  end
  handle_asynchronously :mark_exported, priority: Delayed::LOW_PRIORITY, max_attempts: 1

  def generate
    job_progress.update_attribute(:completion, PERCENTAGE_COMPLETE[:generating])
    update_attribute(:workflow_state, 'generating')
    convert_to_epub
  end
  handle_asynchronously :generate, priority: Delayed::LOW_PRIORITY, max_attempts: 1

  def mark_as_generated
    job_progress.complete! if job_progress.running?
    update_attribute(:workflow_state, 'generated')
  end

  def mark_as_failed
    job_progress.try :fail!
    update_attribute(:workflow_state, 'failed')
  end

  # Epub Exportable overrides
  def content_cartridge
    self.content_export.attachment
  end

  def convert_to_epub
    begin
      file_paths = super
    rescue => e
      mark_as_failed
      raise e
    end

    file_paths.each do |file_path|
      create_attachment_from_path!(file_path)
    end
    mark_as_generated
    file_paths.each {|file_path| cleanup_file_path!(file_path) }
  end
  handle_asynchronously :convert_to_epub, priority: Delayed::LOW_PRIORITY, max_attempts: 1

  def create_attachment_from_path!(file_path)
    begin
      mime_type = MIME::Types.type_for(file_path).first
      file = Rack::Multipart::UploadedFile.new(
        file_path,
        mime_type.try(:content_type)
      )
      self.attachments.create({
        filename: File.basename(file_path),
        uploaded_data: file
      })
    rescue Errno::ENOENT => e
      mark_as_failed
      raise e
    ensure
      file.try(:close)
    end
  end

  def cleanup_file_path!(file_path)
    FileUtils.rm_rf(file_path, secure: true) if File.exist?(file_path)
  end

  def sort_by_content_type?
    self.course.organize_epub_by_content_type
  end
end
