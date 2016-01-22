
# Copyright (C) 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')

describe Quizzes::QuizQuestionsController, type: :request do

  context 'as a teacher' do
    before :once do
      @course = course
      teacher_in_course active_all: true
      @quiz = @course.quizzes.create!(:title => "A Sample Quiz")
    end

    describe "GET /courses/:course_id/quizzes/:quiz_id/questions (index)" do
      it "returns a list of questions" do
        questions = (1..10).map do |n|
          @quiz.quiz_questions.create!(:question_data => { :question_name => "Question #{n}" })
        end

        json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
                        :controller => "quizzes/quiz_questions", :action => "index", :format => "json",
                        :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s)

        question_ids = json.collect { |q| q['id'] }
        expect(question_ids).to eq questions.map(&:id)
      end

      it "calls api_user_content for each question and answer text" do
        (1..3).map do |n|
          @quiz.quiz_questions.create!(:question_data => {
            :question_name => "Question #{n}",
            "answers" => [{"id" => 1, "text" => "foo foo"}, {"id" => 2}]
          })
        end

        Quizzes::QuizQuestionsController.any_instance
          .expects(:api_user_content)
          .times(6)

        api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
                 :controller => "quizzes/quiz_questions", :action => "index", :format => "json",
                 :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s)
      end

      it "returns a list of questions which do not include previously deleted questions" do
        question1 = @quiz.quiz_questions.create!(:question_data => { :question_name => "Question 1"})
        question2 = @quiz.quiz_questions.create!(:question_data => { :question_name => "Question 2"})
        question1.destroy
        json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
                        :controller => "quizzes/quiz_questions", :action => "index", :format => "json",
                        :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s)
        question_ids = json.collect {|q| q['id'] }
        expect(question_ids).to eq [question2.id]
      end

      context 'given a submission id and attempt' do
        it 'returns the list of questions that were used for the submission' do
          question1 = @quiz.quiz_questions.create!(:question_data => { :question_name => "Question 1"})
          question2 = @quiz.quiz_questions.create!(:question_data => { :question_name => "Question 2"})

          @quiz.generate_quiz_data
          @quiz.save

          qs = @quiz.generate_submission(@teacher)

          question1.destroy

          json = api_call(
            :get,
            "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
            {
              :controller => "quizzes/quiz_questions",
              :action => "index",
              :format => "json",
              :course_id => @course.id.to_s,
              :quiz_id => @quiz.id.to_s
            },
            {
              quiz_submission_id: qs.id,
              quiz_submission_attempt: qs.attempt
            })

          question_ids = json.collect {|q| q['id'] }.sort
          expect(question_ids).to eq [question1.id, question2.id]
        end
      end
    end

    describe "GET /courses/:course_id/quizzes/:quiz_id/questions/:id (show)" do
      context "existing question" do
        before do
          @question = @quiz.quiz_questions.create!(:question_data => {
                                                                      "question_name"=>"Example Question", "assessment_question_id"=>"",
                                                                      "question_type"=>"multiple_choice_question", "points_possible"=>"1",
                                                                      "correct_comments"=>"", "incorrect_comments"=>"", "neutral_comments"=>"",
                                                                      "question_text"=>"<p>What's your favorite color?</p>", "position"=>"0",
                                                                      "text_after_answers"=>"", "matching_answer_incorrect_matches"=>"",
                                                                      "answers"=>[]
                                                                      })

          @json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions/#{@question.id}",
                           :controller => "quizzes/quiz_questions", :action => "show", :format => "json",
                           :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s, :id => @question.id.to_s)


          @json.symbolize_keys!
        end

        it "has only the allowed question output fields" do
          question_fields = Api::V1::QuizQuestion::API_ALLOWED_QUESTION_OUTPUT_FIELDS[:only].map(&:to_sym) +  Api::V1::QuizQuestion::API_ALLOWED_QUESTION_DATA_OUTPUT_FIELDS.map(&:to_sym)
          expect(question_fields).to include(:correct_comments_html)
          @json.keys.each { |key| expect(question_fields.to_s).to include(key.to_s) }
        end

        it "has the question data fields" do
          Api::V1::QuizQuestion::API_ALLOWED_QUESTION_DATA_OUTPUT_FIELDS.map(&:to_sym).each do |field|
            expect(@json).to have_key(field)

            # ugh... due to wonkiness in Question#question_data's treatment of keys,
            # and the fact that symbolize_keys doesn't recurse, we resort to this.
            if @json[field].is_a?(Array) && @question.question_data[field].is_a?(Array)
              expect(@json[field].map(&:symbolize_keys)).to eq @question.question_data[field].map(&:symbolize_keys)
            else
              expect(@json[field]).to eq @question.question_data.symbolize_keys[field]
            end
          end
        end
      end

      context "api content translation" do
        it "should translate question text" do
          should_translate_user_content(@course) do |content|
            @question = @quiz.quiz_questions.create!(:question_data => {
                "question_name"=>"Example Question",
                "question_type"=>"multiple_choice_question",
                "points_possible"=>"1",
                "question_text"=>content,
                "answers"=>[]
              })

            json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions/#{@question.id}",
              :controller => "quizzes/quiz_questions", :action => "show", :format => "json",
              :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s, :id => @question.id.to_s)

            json['question_text']
          end
        end

        it "should translate answer html" do
          should_translate_user_content(@course) do |content|
            plain_answer_txt = "plz don't & escape me"
            @question = @quiz.quiz_questions.create!(:question_data => {
                "question_name"=>"Example Question",
                "question_type"=>"multiple_choice_question",
                "points_possible"=>"1",
                "question_text"=>"stuff",
                "answers"=>[{"text" => plain_answer_txt}, {"html" => content}]
              })

            json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions/#{@question.id}",
              :controller => "quizzes/quiz_questions", :action => "show", :format => "json",
              :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s, :id => @question.id.to_s)

            expect(json['answers'][0]['text']).to eq plain_answer_txt
            json['answers'][1]['html']
          end
        end
      end

      context "non-existent question" do
        before do
          @json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions/9034831",
                           {:controller => "quizzes/quiz_questions", :action => "show", :format => "json", :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s, :id => "9034831"},
                             {}, {}, {:expected_status => 404})
        end

        it "should return a not found error message" do
          expect(@json.inspect).to include "does not exist"
        end
      end
    end
  end

  context 'as a student' do
    before :once do
      course_with_student :active_all => true

      @quiz = @course.quizzes.create!(:title => 'quiz')
      @quiz.published_at = Time.now
      @quiz.workflow_state = 'available'
      @quiz.save!
    end

    context 'whom has not started the quiz' do
      describe 'GET /courses/:course_id/quizzes/:quiz_id/questions (index)' do
        it "should be unauthorized" do
          raw_api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
                              :controller => "quizzes/quiz_questions", :action => "index", :format => "json",
                              :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s)
          assert_status(401)
        end
      end

      describe 'GET /courses/:course_id/quizzes/:quiz_id/questions/:id (show) ' do
        it "should be unauthorized" do
          @question = @quiz.quiz_questions.create!(:question_data => multiple_choice_question_data)

          raw_api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions/#{@question.id}",
                             :controller => "quizzes/quiz_questions", :action => "show", :format => "json",
                             :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s, :id => @question.id)
          assert_status(401)
        end
      end
    end

    context 'whom has started a quiz' do
      before :once do
        @quiz.generate_submission(@student)
      end

      describe 'GET /courses/:course_id/quizzes/:quiz_id/questions (index)' do
        it "should be unauthorized" do
          raw_api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions",
                              :controller => "quizzes/quiz_questions", :action => "index", :format => "json",
                              :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s)
          assert_status(401)
        end
      end

      describe 'GET /courses/:course_id/quizzes/:quiz_id/questions/:id (show)' do
        it "should be unauthorized" do
          @question = @quiz.quiz_questions.create!(:question_data => multiple_choice_question_data)

          raw_api_call(:get, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/questions/#{@question.id}",
                             :controller => "quizzes/quiz_questions", :action => "show", :format => "json",
                             :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s, :id => @question.id)
          assert_status(401)
        end
      end
    end
  end
end
