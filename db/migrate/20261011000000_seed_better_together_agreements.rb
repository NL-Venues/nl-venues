# frozen_string_literal: true

# CE gates publishing public or community-visible records on the content publishing agreement, and the
# community creation agreement on creating communities. Neither exists on an instance upgraded from CE 0.10:
# the default agreements come from `rake better_together:generate:agreements`, which CE never runs on upgrade,
# so nobody could publish until someone ran it by hand. This runs that task as part of the deploy.
#
# Idempotent: the task finds or creates each agreement, its terms and its page by identifier (CLEAR is
# removed from the environment so it can never rebuild from scratch), and reaffirms the standard agreement
# attributes (title, description, kind, required_for) on the three agreements that already exist.
# `down` is a no-op: removing agreements people have accepted would orphan their acceptances.
class SeedBetterTogetherAgreements < ActiveRecord::Migration[8.1]
  TASK = 'better_together:generate:agreements'

  def up
    return unless table_exists?(:better_together_agreements) && table_exists?(:better_together_agreement_terms)

    previous_clear = ENV.delete('CLEAR')
    Rails.application.load_tasks unless Rake::Task.task_defined?(TASK)
    task = Rake::Task[TASK]
    task.reenable
    task.invoke
  ensure
    ENV['CLEAR'] = previous_clear if previous_clear
  end

  def down
    # Intentionally empty, see the header comment.
  end
end
