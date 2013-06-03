class DirectSubmissionsController < ApplicationController
  # GET /direct_submissions
  # GET /direct_submissions.json
  def index
    @direct_submissions = DirectSubmission.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @direct_submissions }
    end
  end

  # GET /direct_submissions/1
  # GET /direct_submissions/1.json
  def show
    @direct_submission = DirectSubmission.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @direct_submission }
    end
  end

  # GET /direct_submissions/new
  # GET /direct_submissions/new.json
  def new
    @direct_submission = DirectSubmission.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @direct_submission }
    end
  end

  # GET /direct_submissions/1/edit
  def edit
    @direct_submission = DirectSubmission.find(params[:id])
  end

  # POST /direct_submissions
  # POST /direct_submissions.json
  def create
    @direct_submission = DirectSubmission.new(params[:direct_submission])

    respond_to do |format|
      if @direct_submission.save
        format.html { redirect_to @direct_submission, notice: 'Direct submission was successfully created.' }
        format.json { render json: @direct_submission, status: :created, location: @direct_submission }
      else
        format.html { render action: "new" }
        format.json { render json: @direct_submission.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /direct_submissions/1
  # PUT /direct_submissions/1.json
  def update
    @direct_submission = DirectSubmission.find(params[:id])

    respond_to do |format|
      if @direct_submission.update_attributes(params[:direct_submission])
        format.html { redirect_to @direct_submission, notice: 'Direct submission was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @direct_submission.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /direct_submissions/1
  # DELETE /direct_submissions/1.json
  def destroy
    @direct_submission = DirectSubmission.find(params[:id])
    @direct_submission.destroy

    respond_to do |format|
      format.html { redirect_to direct_submissions_url }
      format.json { head :no_content }
    end
  end
end
