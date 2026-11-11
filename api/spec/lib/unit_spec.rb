require "rails_helper"

RSpec.describe Units do
  describe ".to_base_unit" do
    it "converts grams to grams" do
      expect(Units.to_base_unit(1000, "g")).to eq(1000.0)
    end

    it "converts kilograms to grams" do
      expect(Units.to_base_unit(1, "kg")).to eq(1000.0)
    end

    it "converts milliliters to milliliters" do
      expect(Units.to_base_unit(1000, "ml")).to eq(1000.0)
    end

    it "converts liters to milliliters" do
      expect(Units.to_base_unit(1, "l")).to eq(1000.0)
    end

    it "raises an error for unknown units" do
      expect { Units.to_base_unit(1, "unknown") }.to raise_error(ArgumentError, "Unknown unit: unknown")
    end
  end
end