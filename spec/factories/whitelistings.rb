FactoryBot.define do
  factory :whitelisting do
    member_id 1
    ip_address "MyString"
    token "MyString"
    expired_at "2021-02-25 17:26:00"
    authorised_ip false
  end
end
