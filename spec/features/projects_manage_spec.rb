require "rails_helper"

RSpec.describe "managing projects", js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project) }

  before do
    login_as(user, scope: :user)
  end

  it "allows me to sign in" do
    visit root_path
    expect(page).to have_content "Sign out"
  end

  it "allows me to add a project" do
    visit root_path
    click_link "Add a Project"
    fill_in "project[title]", with: "Super Project"
    click_button "Create"
    expect(Project.count).to eq 1
  end

  it "allows me to clone a project" do
    visit project_path(id: project.id)
    click_link "Clone Project"
    expect(Project.count).to eq 2
    expect(Project.last.title).to eq "Copy of #{project.title}"
  end

  it "allows me to edit a project" do
    visit project_path(id: project.id)
    click_link "Edit or Delete Project"
    fill_in "project[title]", with: "New Project"
    click_button "Save Changes"
    expect(page).to have_content "Project updated!"
  end

  it "allows me to archive a project" do
    visit project_path(id: project.id)
    click_link "Archive Project"
    expect(page).to have_content "Unarchive Project"
    expect(project.reload).to be_archived
  end

  it "allows me to delete a project", js: false do
    visit project_path(id: project.id)
    click_link "Edit or Delete Project"
    click_link "Delete Project"
    expect(Project.count).to eq 0
  end

  it "allows me to delete a project" do
    visit project_path(id: project.id)
    click_link "Edit or Delete Project"
    accept_confirm do
      click_link "Delete Project"
    end
    expect(page).not_to have_content 'Edit or Delete Project'
    expect(Project.count).to eq 0
  end

  context "import & Export" do
    before do
      project.stories.create(title: "php upgrade", description: "quick php upgrade")
    end

    it "allows me to export a CSV", js: false do
      visit project_path(id: project.id)
      find("#import-export").click

      click_on "Export"
      expect(page.response_headers["Content-Type"]).to eql "text/csv"
      expect(page.source).to include("php upgrade")
    end

    it "allows me to export a CSV" do
      visit project_path(id: project.id)
      find("#import-export").click

      click_on "Export"
      expect(page.source).to include("php upgrade")
    end

    it "allows me to import a CSV" do
      visit project_path(id: project.id)
      find("#import-export").click
      page.attach_file("file", (Rails.root + "spec/fixtures/test.csv").to_s)
      click_on "Import"
      expect(project.stories.count).to be > 1
      expect(project.stories.map(&:title).join).to include("php upgrade")
      expect(page.text).to include("success")
      expect(page.current_path).to eql project_path(project.id)
    end

    it "allows me to update existing stories on import" do
      csv_path = (Rails.root + "tmp/stories.csv").to_s
      story = project.stories.first
      csv_content = "id,title,description,position\n#{story.id},#{story.title},blank!,#{story.position}"
      File.write(csv_path, csv_content)

      story_count = project.stories.count
      visit project_path(id: project.id)
      find("#import-export").click
      page.attach_file("file", csv_path)
      click_on "Import"
      expect(project.stories.count).to be story_count
      expect(project.stories.map(&:description).join).to_not include("quick")
    end
  end
end
