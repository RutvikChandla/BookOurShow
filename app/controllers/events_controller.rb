class EventsController < ApplicationController
  before_action :set_event, only: %i[ show edit update destroy book ]

  # GET /events or /events.json
  def index
    @events = Event.all
  end

  # GET /events/1 or /events/1.json
  def show
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit

  end

  # POST /events or /events.json
  def create
    @event = Event.new(event_params)
    respond_to do |format|
      if @event.save
        Ticket.create_empty_tickets(@event)
        format.html { redirect_to event_url(@event), notice: "Event was successfully created." }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  def book
    error_msg = nil
    mutex = Mutex.new
    number_of_threads = params[:number_of_users].to_i
    sucess_count = 0
    read_lock = params[:for_share].to_i
    exclusive_lock = params[:for_update].to_i
    exclusive_lock_with_skip_lock = params[:for_update_with_skip_lock].to_i
    threads = []
    expired_at = Time.now.to_i + (@event.timeout * 60)
    start_time = Time.now
    number_of_threads.times do |index|
      threads << Thread.new do
        conn = ActiveRecord::Base.connection
        Ticket.transaction do
          for_share = read_lock == 1 ? " FOR SHARE" : ""
          for_update = exclusive_lock == 1 ? " FOR UPDATE" : ""
          for_update_with_skip_lock = exclusive_lock_with_skip_lock == 1 ? " FOR UPDATE SKIP LOCKED" : ""
          min_id = conn.execute("SELECT id from tickets WHERE event_id = #{@event.id} AND user_id IS NULL ORDER BY id LIMIT 1#{for_share}#{for_update}#{for_update_with_skip_lock}").first.first rescue -1
          if min_id != -1
            conn.execute("UPDATE tickets SET user_id = #{index}, expired_at = #{expired_at} WHERE id = #{min_id}")
          end
          mutex.synchronize { sucess_count += 1 }
        rescue => e
          puts "Error booking tickets: #{e.message}"
          mutex.synchronize { error_msg = e.message }
        end
      end
    end
    threads.each(&:join)

    time_taken = (Time.now - start_time) * 1000
    flash[:notice] = "Booked #{sucess_count} tickets in #{time_taken} ms"
    if error_msg
      flash[:alert] = "#{number_of_threads - sucess_count} tickets failed to book: #{error_msg}"
    end
    redirect_to @event
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to event_url(@event), notice: "Event was successfully updated." }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    @event.destroy!

    respond_to do |format|
      format.html { redirect_to events_url, notice: "Event was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:name, :capacity, :timeout)
    end
end
