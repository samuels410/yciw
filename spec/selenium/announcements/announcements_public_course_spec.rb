require_relative '../common'
require_relative '../helpers/announcements_common'

describe "announcements public course" do
  include_context "in-process server selenium tests"
  include AnnouncementsCommon

  context "replies on announcements" do
    before :each do
      course_with_teacher(active_all: true, is_public: true) # sets @teacher and @course
      expect(@course.is_public).to be_truthy
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true).user

      @context = @course
      @announcement = announcement_model(user: @teacher) # sets @a

      s1e = @announcement.discussion_entries.create!(:user => @student1, :message => "Hello I'm student 1!")
      @announcement.discussion_entries.create!(:user => @student2, :parent_entry => s1e, :message => "Hello I'm student 2!")
    end

    it "does not display replies on announcements to unauthenticated users", priority: "1", test_id: 220381 do
      get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
      wait_for_ajaximations
      keep_trying_until { expect(f('#discussion_subentries span').text).to match(/must log in/i) }
    end

    it "does not display replies on announcements to users not enrolled in the course", priority: "1", test_id: 220382 do
      user_session(user)

      get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
      wait_for_ajaximations
      keep_trying_until { expect(f('#discussion_subentries span').text).to match(/must log in/i) }
    end
  end
end
