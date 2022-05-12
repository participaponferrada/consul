require "rails_helper"

describe "Level two verification" do
  scenario "Verification with residency" do
    create(:geozone)
    user = create(:user)
    login_as(user)

    visit account_path
    click_link "Verify my account"

    verify_residence
  end

  context "In Spanish, with no fallbacks" do
    before do
      skip unless I18n.available_locales.include?(:es)
      allow(I18n.fallbacks).to receive(:[]).and_return([:es])
    end

    scenario "Works normally" do
      user = create(:user)
      login_as(user)

      visit verification_path(locale: :es)
      verify_residence
    end
  end
end
