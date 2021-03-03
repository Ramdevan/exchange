FactoryGirl.define do
  factory :lending_auto_transfer do
    currency "MyString"
    is_auto_transfer false
    member nil
    lending nil
  end
end
