require_relative "./diff_parser"
require_relative './user_config'

module RuboCop::Canvas
  class Comments
    def self.build(raw_diff_tree, cop_output, git_dir: nil, boyscout_mode: false, include_git_dir_in_output: true)
      diff = DiffParser.new(raw_diff_tree)
      comments = self.new(diff, git_dir)
      comments.on_output(cop_output, boyscout_mode, include_git_dir_in_output)
    end

    attr_reader :diff
    def initialize(diff, git_dir = nil)
      @diff = diff
      @git_dir = git_dir
    end

    def on_output(cop_output, boyscout_mode = false, include_git_dir_in_output = true)
      comments = []
      cop_output['files'].each do |file|
        path = file['path']
        path = path[@git_dir.length..-1] if @git_dir
        file['offenses'].each do |offense|
          if diff.relevant?(path, line_number(offense), boyscout_mode || severe?(offense))
            comments << transform_to_gergich_comment(include_git_dir_in_output ? file['path'] : path, offense)
          end
        end
      end
      comments
    end

    private

    SEVERITY_MAPPING = {
      'refactor' => 'info',
      'convention' => 'info',
      'warning' => 'warn',
      'error' => 'error',
      'fatal' => 'error'
    }.freeze

    def severe?(offense)
      if UserConfig.only_report_errors?
        %w(error fatal).include?(offense['severity'])
      else
        %w(warning error fatal).include?(offense['severity'])
      end
    end

    def transform_to_gergich_comment(path, offense)
      {
        path: path,
        position: line_number(offense),
        message: offense['message'],
        severity: SEVERITY_MAPPING[offense['severity']]
      }
    end

    def line_number(offense)
      offense['location']['line']
    end

  end

end