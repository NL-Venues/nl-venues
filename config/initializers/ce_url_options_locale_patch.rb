# frozen_string_literal: true

# Temporary workaround for Community Engine main (d6bda4df4).
# In host-app controllers the view class's own `default_url_options` (from the
# main app routes) shadows BetterTogether::ApplicationHelper#default_url_options,
# so ApplicationHelper#method_missing appends `{}` and a record passed
# positionally to an engine URL helper is read as the :locale segment.
# Remove once CE builds engine URL options from the view's `url_options`.
module CeUrlOptionsLocalePatch
  def method_missing(name, *args, &)
    return super unless better_together_url_helper?(name)

    options = default_url_options.reverse_merge(locale: I18n.locale)
    args = args.first.is_a?(Hash) ? [args.first.merge(options)] : [*args, options]
    BetterTogether::Engine.routes.url_helpers.public_send(name, *args, &)
  end

  def respond_to_missing?(name, include_private = false)
    better_together_url_helper?(name) || super
  end
end

Rails.application.config.to_prepare do
  BetterTogether::ApplicationHelper.prepend(CeUrlOptionsLocalePatch)
end
