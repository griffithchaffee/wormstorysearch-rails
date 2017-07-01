FactoryGirl.define do
  sequence(:uniq_i) { |i| i }
  sequence(:uniq_s) { |i| "uniq#{FactoryGirl.generate(:uniq_i)}" }
  sequence(:email) { |i| "#{FactoryGirl.generate(:uniq_s)}@example.com" }
  sequence(:time_in_past) { |i| rand(0..10_000).hours.ago }
  sequence(:date_in_past) { |i| FactoryGirl.generate(:time_in_past).to_date }
end
