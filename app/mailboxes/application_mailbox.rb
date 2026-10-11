# frozen_string_literal: true

# Root Action Mailbox for inbound mail. CE owns the routing (tenant by recipient
# domain, fail-closed aliases); the host only opts in by subclassing.
class ApplicationMailbox < BetterTogether::ApplicationMailbox
end
