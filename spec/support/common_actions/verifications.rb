module Verifications
  def select_date(values, selector)
    selector = selector[:from]
    day, month, year = values.split("-")
    select day,   from: "#{selector}_3i"
    select month, from: "#{selector}_2i"
    select year,  from: "#{selector}_1i"
  end

  def verify_residence
    select "DNI", from: "residence_document_type"
    fill_in "residence_document_number", with: "12345678Z"
    select_date "31-#{I18n.l(Date.current.at_end_of_year, format: "%B")}-1980",
                from: "residence_date_of_birth"

    check "residence_terms_of_service"

    click_button "new_residence_submit"
    expect(page).to have_content I18n.t("verification.residence.create.flash.success")
  end

  def officing_verify_residence
    select "DNI", from: "residence_document_type"
    fill_in "residence_document_number", with: "12345678Z"
    fill_in "residence_year_of_birth", with: "1980"

    click_button "Validate document"

    expect(page).to have_content "Document verified with Census"
  end

  def expect_badge_for(resource_name, resource)
    within("##{resource_name}_#{resource.id}") do
      expect(page).to have_css ".label.round"
      expect(page).to have_content "Employee"
    end
  end

  def expect_no_badge_for(resource_name, resource)
    within("##{resource_name}_#{resource.id}") do
      expect(page).not_to have_css ".label.round"
      expect(page).not_to have_content "Employee"
    end
  end

  def fill_in_ckeditor(label, with:)
    locator = find("label", text: label)[:for]

    until page.execute_script("return CKEDITOR.instances.#{locator}.status === 'ready';") do
      sleep 0.01
    end

    within("#cke_#{locator}") do
      within_frame(0) { find("body").set(with) }
    end
  end

  def fill_in_markdown_editor(label, with:)
    click_link "Launch text editor"
    fill_in label, with: with

    within(".fullscreen") do
      click_link "Close text editor"
    end
  end
end
