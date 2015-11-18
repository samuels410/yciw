module Canvas
  module Help
    def self.default_links
      [
        {
          :available_to => ['student'],
          :text => I18n.t('#help_dialog.instructor_question', 'Ask Your Instructor a Question'),
          :subtext => I18n.t('#help_dialog.instructor_question_sub', 'Questions are submitted to your instructor'),
          :url => '#teacher_feedback'
        }
      ]
    end
  end
end
