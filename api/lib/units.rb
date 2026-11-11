# Keep in sync with the *_unit_allowed check constraints. Adding a unit needs a migration.
module Units
  DIMENSIONS = {
    "g" => :mass, "kg" => :mass,
    "ml" => :volume, "l" => :volume,
    "each" => :count
  }.freeze

  UNIT_CONVERSION_FACTORS = {
    "g" => 1.0, "kg" => 1000.0,
    "ml" => 1.0, "l" => 1000.0
  }.freeze

  ALL = DIMENSIONS.keys.freeze

  def self.compatible?(a, b)
    DIMENSIONS.key?(a) && DIMENSIONS[a] == DIMENSIONS[b]
  end

  def self.to_base_unit(quantity, unit)
    factor = UNIT_CONVERSION_FACTORS[unit]
    raise ArgumentError, "Unknown unit: #{unit}" unless factor

    quantity * factor
  end
end
