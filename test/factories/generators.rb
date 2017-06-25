FactoryGirl.define do
  sequence(:uniq_i) { |i| i }
  sequence(:uniq_s) { |i| "uniq#{FactoryGirl.generate(:uniq_i)}" }
  sequence(:time_in_past) { |i| rand(1..1_000).hours.ago }
  sequence(:date_in_past) { |i| FactoryGirl.generate(:time_in_past).to_date }
end
