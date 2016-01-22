# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggersEnrollmentsInsertAndEnrollmentsUpdateAndSubmissionsUpdateAndSubmissionsInsert < ActiveRecord::Migration
  tag :predeploy

  def self.up
    drop_trigger("enrollments_after_insert_row_when_new_workflow_state_active__tr", "enrollments", :generated => true)

    drop_trigger("enrollments_after_update_row_when_new_workflow_state_old_wor_tr", "enrollments", :generated => true)

    drop_trigger("submissions_after_update_row_tr", "submissions", :generated => true)

    drop_trigger("submissions_after_update_row_when_old_submission_type_is_not_tr", "submissions", :generated => true)

    drop_trigger("submissions_after_insert_row_tr", "submissions", :generated => true)

    drop_trigger("submissions_after_insert_row_when_new_submission_type_is_not_tr", "submissions", :generated => true)

    create_trigger("enrollments_after_insert_row_when_new_workflow_state_active__tr", :generated => true, :compatibility => 1).
        on("enrollments").
        after(:insert).
        where("NEW.workflow_state = 'active'") do
      {:mysql=>"\n    IF NOT EXISTS (SELECT 1 FROM enrollments WHERE workflow_state = 'active' AND user_id = NEW.user_id AND course_id = NEW.course_id AND id <> NEW.id LIMIT 1) THEN\n      UPDATE assignments, submissions SET needs_grading_count = needs_grading_count + 1\n      WHERE context_id = NEW.course_id\n        AND context_type = 'Course'\n        AND assignments.id = submissions.assignment_id\n        AND submissions.user_id = NEW.user_id\n        AND ( submissions.submission_type IS NOT NULL AND submissions.workflow_state IN ('submitted', 'pending_review') AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission ) );\n    END IF;", :default=>"    UPDATE assignments SET needs_grading_count = needs_grading_count + 1\n    WHERE context_id = NEW.course_id\n      AND context_type = 'Course'\n      AND EXISTS (\n        SELECT 1\n        FROM submissions\n        WHERE user_id = NEW.user_id\n          AND assignment_id = assignments.id\n          AND ( submissions.submission_type IS NOT NULL AND submissions.workflow_state IN ('submitted', 'pending_review') AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission ) )\n        LIMIT 1\n      )\n      AND NOT EXISTS (SELECT 1 FROM enrollments WHERE workflow_state = 'active' AND user_id = NEW.user_id AND course_id = NEW.course_id AND id <> NEW.id LIMIT 1);"}
    end

    create_trigger("enrollments_after_update_row_when_new_workflow_state_old_wor_tr", :generated => true, :compatibility => 1).
        on("enrollments").
        after(:update).
        where("NEW.workflow_state <> OLD.workflow_state AND (NEW.workflow_state = 'active' OR OLD.workflow_state = 'active')") do
      {:mysql=>"\n    IF NOT EXISTS (SELECT 1 FROM enrollments WHERE workflow_state = 'active' AND user_id = NEW.user_id AND course_id = NEW.course_id AND id <> NEW.id LIMIT 1) THEN\n      UPDATE assignments, submissions SET needs_grading_count = needs_grading_count + CASE WHEN NEW.workflow_state = 'active' THEN 1 ELSE -1 END\n      WHERE context_id = NEW.course_id\n        AND context_type = 'Course'\n        AND assignments.id = submissions.assignment_id\n        AND submissions.user_id = NEW.user_id\n        AND ( submissions.submission_type IS NOT NULL AND submissions.workflow_state IN ('submitted', 'pending_review') AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission ) );\n    END IF;", :default=>"    UPDATE assignments SET needs_grading_count = needs_grading_count + CASE WHEN NEW.workflow_state = 'active' THEN 1 ELSE -1 END\n    WHERE context_id = NEW.course_id\n      AND context_type = 'Course'\n      AND EXISTS (\n        SELECT 1\n        FROM submissions\n        WHERE user_id = NEW.user_id\n          AND assignment_id = assignments.id\n          AND ( submissions.submission_type IS NOT NULL AND submissions.workflow_state IN ('submitted', 'pending_review') AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission ) )\n        LIMIT 1\n      )\n      AND NOT EXISTS (SELECT 1 FROM enrollments WHERE workflow_state = 'active' AND user_id = NEW.user_id AND course_id = NEW.course_id AND id <> NEW.id LIMIT 1);"}
    end

    create_trigger("submissions_after_update_row_tr", :generated => true, :compatibility => 1).
        on("submissions").
        after(:update) do |t|
      t.where("( OLD.submission_type IS NOT NULL AND OLD.workflow_state IN ('submitted', 'pending_review') AND ( OLD.score IS NULL OR NOT OLD.grade_matches_current_submission ) ) <> ( NEW.submission_type IS NOT NULL AND NEW.workflow_state IN ('submitted', 'pending_review') AND ( NEW.score IS NULL OR NOT NEW.grade_matches_current_submission ) )") do
        <<-SQL_ACTIONS
      UPDATE assignments
      SET needs_grading_count = needs_grading_count + CASE WHEN ( NEW.submission_type IS NOT NULL AND NEW.workflow_state IN ('submitted', 'pending_review') AND ( NEW.score IS NULL OR NOT NEW.grade_matches_current_submission ) ) THEN 1 ELSE -1 END
      WHERE id = NEW.assignment_id;
        SQL_ACTIONS
      end
    end

    create_trigger("submissions_after_insert_row_tr", :generated => true, :compatibility => 1).
        on("submissions").
        after(:insert) do |t|
      t.where(" NEW.submission_type IS NOT NULL AND NEW.workflow_state IN ('submitted', 'pending_review') AND ( NEW.score IS NULL OR NOT NEW.grade_matches_current_submission ) ") do
        <<-SQL_ACTIONS
      UPDATE assignments
      SET needs_grading_count = needs_grading_count + 1
      WHERE id = NEW.assignment_id;
        SQL_ACTIONS
      end
    end
  end

  def self.down
    drop_trigger("enrollments_after_insert_row_when_new_workflow_state_active__tr", "enrollments", :generated => true)

    drop_trigger("enrollments_after_update_row_when_new_workflow_state_old_wor_tr", "enrollments", :generated => true)

    drop_trigger("submissions_after_update_row_tr", "submissions", :generated => true)

    drop_trigger("submissions_after_update_row_when_old_submission_type_is_not_tr", "submissions", :generated => true)

    drop_trigger("submissions_after_insert_row_tr", "submissions", :generated => true)

    drop_trigger("submissions_after_insert_row_when_new_submission_type_is_not_tr", "submissions", :generated => true)

    create_trigger("enrollments_after_insert_row_when_new_workflow_state_active__tr", :generated => true, :compatibility => 1).
        on("enrollments").
        after(:insert).
        where("NEW.workflow_state = 'active'") do
      {:mysql=>"\n    IF NOT EXISTS (SELECT 1 FROM enrollments WHERE workflow_state = 'active' AND user_id = NEW.user_id AND course_id = NEW.course_id AND id <> NEW.id LIMIT 1) THEN\n      UPDATE assignments, submissions SET needs_grading_count = needs_grading_count + 1\n      WHERE context_id = NEW.course_id\n        AND context_type = 'Course'\n        AND assignments.id = submissions.assignment_id\n        AND submissions.user_id = NEW.user_id\n        AND ( submissions.submission_type IS NOT NULL AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission OR submissions.workflow_state IN ('submitted', 'pending_review') ) );\n    END IF;", :default=>"    UPDATE assignments SET needs_grading_count = needs_grading_count + 1\n    WHERE context_id = NEW.course_id\n      AND context_type = 'Course'\n      AND EXISTS (\n        SELECT 1\n        FROM submissions\n        WHERE user_id = NEW.user_id\n          AND assignment_id = assignments.id\n          AND ( submissions.submission_type IS NOT NULL AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission OR submissions.workflow_state IN ('submitted', 'pending_review') ) )\n        LIMIT 1\n      )\n      AND NOT EXISTS (SELECT 1 FROM enrollments WHERE workflow_state = 'active' AND user_id = NEW.user_id AND course_id = NEW.course_id AND id <> NEW.id LIMIT 1);"}
    end

    create_trigger("enrollments_after_update_row_when_new_workflow_state_old_wor_tr", :generated => true, :compatibility => 1).
        on("enrollments").
        after(:update).
        where("NEW.workflow_state <> OLD.workflow_state AND (NEW.workflow_state = 'active' OR OLD.workflow_state = 'active')") do
      {:mysql=>"\n    IF NOT EXISTS (SELECT 1 FROM enrollments WHERE workflow_state = 'active' AND user_id = NEW.user_id AND course_id = NEW.course_id AND id <> NEW.id LIMIT 1) THEN\n      UPDATE assignments, submissions SET needs_grading_count = needs_grading_count + CASE WHEN NEW.workflow_state = 'active' THEN 1 ELSE -1 END\n      WHERE context_id = NEW.course_id\n        AND context_type = 'Course'\n        AND assignments.id = submissions.assignment_id\n        AND submissions.user_id = NEW.user_id\n        AND ( submissions.submission_type IS NOT NULL AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission OR submissions.workflow_state IN ('submitted', 'pending_review') ) );\n    END IF;", :default=>"    UPDATE assignments SET needs_grading_count = needs_grading_count + CASE WHEN NEW.workflow_state = 'active' THEN 1 ELSE -1 END\n    WHERE context_id = NEW.course_id\n      AND context_type = 'Course'\n      AND EXISTS (\n        SELECT 1\n        FROM submissions\n        WHERE user_id = NEW.user_id\n          AND assignment_id = assignments.id\n          AND ( submissions.submission_type IS NOT NULL AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission OR submissions.workflow_state IN ('submitted', 'pending_review') ) )\n        LIMIT 1\n      )\n      AND NOT EXISTS (SELECT 1 FROM enrollments WHERE workflow_state = 'active' AND user_id = NEW.user_id AND course_id = NEW.course_id AND id <> NEW.id LIMIT 1);"}
    end

    create_trigger("submissions_after_update_row_tr", :generated => true, :compatibility => 1).
        on("submissions").
        after(:update) do |t|
      t.where("( OLD.submission_type IS NOT NULL AND ( OLD.score IS NULL OR NOT OLD.grade_matches_current_submission OR OLD.workflow_state IN ('submitted', 'pending_review') ) ) <> ( NEW.submission_type IS NOT NULL AND ( NEW.score IS NULL OR NOT NEW.grade_matches_current_submission OR NEW.workflow_state IN ('submitted', 'pending_review') ) )") do
        <<-SQL_ACTIONS
      UPDATE assignments
      SET needs_grading_count = needs_grading_count + CASE WHEN ( NEW.submission_type IS NOT NULL AND ( NEW.score IS NULL OR NOT NEW.grade_matches_current_submission OR NEW.workflow_state IN ('submitted', 'pending_review') ) ) THEN 1 ELSE -1 END
      WHERE id = NEW.assignment_id;
        SQL_ACTIONS
      end
    end

    create_trigger("submissions_after_insert_row_tr", :generated => true, :compatibility => 1).
        on("submissions").
        after(:insert) do |t|
      t.where(" NEW.submission_type IS NOT NULL AND ( NEW.score IS NULL OR NOT NEW.grade_matches_current_submission OR NEW.workflow_state IN ('submitted', 'pending_review') ) ") do
        <<-SQL_ACTIONS
      UPDATE assignments
      SET needs_grading_count = needs_grading_count + 1
      WHERE id = NEW.assignment_id;
        SQL_ACTIONS
      end
    end
  end
end
