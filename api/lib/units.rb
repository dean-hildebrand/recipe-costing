# Keep in sync with the *_unit_allowed check constraints. Adding a unit needs a migration.
module Units
  DIMENSIONS = {
    "g" => :mass, "kg" => :mass,
    "ml" => :volume, "l" => :volume,
    "each" => :count
  }.freeze

  ALL = DIMENSIONS.keys.freeze

  def self.compatible?(a, b)
    DIMENSIONS.key?(a) && DIMENSIONS[a] == DIMENSIONS[b]
  end
end
