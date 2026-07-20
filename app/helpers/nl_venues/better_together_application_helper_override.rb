# frozen_string_literal: true

module NlVenues
  # Ensures Better Together helper route calls keep the current locale in host-app views.
  module BetterTogetherApplicationHelperOverride
    def default_url_options
      super.merge(locale: I18n.locale)
    end

    def method_missing(method, *args, &)
      return better_together.public_send(method, *route_helper_args(args), &) if better_together_url_helper?(method)

      super
    end

    def respond_to_missing?(method, include_private = false)
      better_together_url_helper?(method) || super
    end

    private

    def route_helper_args(args)
      route_options = default_url_options
      return args + [route_options] unless args.last.is_a?(Hash)

      args[0...-1] + [route_options.merge(args.last)]
    end
  end
end
