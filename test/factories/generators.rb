FactoryBot.define do
  sequence(:uniq_i) { |i| i }
  sequence(:uniq_s) { |i| "uniq_#{FactoryBot.generate(:uniq_i)}_s" }
  sequence(:email) { |i| "#{FactoryBot.generate(:uniq_s)}@example.com" }
  sequence(:time_in_past) { |i| rand(5..10_000).hours.ago }
  sequence(:date_in_past) { |i| FactoryBot.generate(:time_in_past).to_date }
end
