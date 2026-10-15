# frozen_string_literal: true

# Custom collection map for venues
# This class is used to create a map of venues, which are collections of spaces
# and buildings. It inherits from VenueMap and overrides the records method to
# return a collection of venues ordered by their creation date.
#
# @see VenueMap
#
# @example
#   venue_map = VenueCollectionMap.new
#   venue_map.records # => returns a collection of venues ordered by creation date
#
# @note This class is used for creating maps of venues in the application and rendered on the venues index view.
class VenueCollectionMap < VenueMap
  # The venues the viewer may see (a policy scope). Without it every venue with a geocoded building is mapped, so
  # callers rendering this map for a viewer must set it (VenuesHelper#venues_map does).
  attr_writer :visible_scope

  # Translations (name, slug), buildings, their spaces and addresses are preloaded so building the points does not
  # query per venue.
  # visible_scope is used as an id subquery, so a policy scope's own joins and ordering do not interfere.
  def self.records(visible_scope = nil)
    scope = mappable_class
    scope = scope.where(id: visible_scope.except(:includes, :preload, :eager_load, :order).select(:id)) if visible_scope
    scope.joins(buildings: [:space]).preload(:string_translations, buildings: %i[string_translations space address])
         .distinct.order(created_at: :desc)
  end

  def records
    @records ||= self.class.records(@visible_scope).to_a
  end

  def leaflet_points
    @leaflet_points ||= records.flat_map(&:leaflet_points).uniq
  end

  def spaces
    @spaces ||= records.flat_map(&:spaces).uniq
  end
end
