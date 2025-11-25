require "test_helper"

module PaddleRails
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should get show" do
      get dashboard_show_url
      assert_response :success
    end
  end
end
