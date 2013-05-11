FactoryGirl.define do
  factory :document do
    title    { Faker::HipsterIpsum.words(3).join ' ' }
    author   { Faker::Name.name }
    filename { Faker::Lorem.words(2).join(['-', ' ', '_'].sample) + '.pdf' }
    tags     { rand(1..4).times.map { Faker::Lorem.word } }

    trait :invalid do
      title  nil
      author nil
    end
  end
end
