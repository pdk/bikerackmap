require 'test_helper'

class DirectSubmissionsControllerTest < ActionController::TestCase
  setup do
    @direct_submission = direct_submissions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:direct_submissions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create direct_submission" do
    assert_difference('DirectSubmission.count') do
      post :create, direct_submission: { lat: @direct_submission.lat, long: @direct_submission.long, photo_url: @direct_submission.photo_url, text: @direct_submission.text }
    end

    assert_redirected_to direct_submission_path(assigns(:direct_submission))
  end

  test "should show direct_submission" do
    get :show, id: @direct_submission
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @direct_submission
    assert_response :success
  end

  test "should update direct_submission" do
    put :update, id: @direct_submission, direct_submission: { lat: @direct_submission.lat, long: @direct_submission.long, photo_url: @direct_submission.photo_url, text: @direct_submission.text }
    assert_redirected_to direct_submission_path(assigns(:direct_submission))
  end

  test "should destroy direct_submission" do
    assert_difference('DirectSubmission.count', -1) do
      delete :destroy, id: @direct_submission
    end

    assert_redirected_to direct_submissions_path
  end
end
