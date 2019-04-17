# frozen_string_literal: true

class EmailProcessor
  def initialize(email)
    @email = email
    @content, @course, @from_address, @owner, @reference_id, @sender = nil
  end

  def process
    define_owner
    define_sender
    define_content_and_reference_id
    dispense_or_thread_ticket
  end

  def retrieve_forwarder_email
    raw_body = @email.raw_body
    expression = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i
    raw_body[expression]
  end

  private

  def define_owner
    recipient_emails = @email.to.pluck(:email)
    @owner = SpecialUsers.wikipedia_experts.find do |expert|
      recipient_emails.include?(expert.email)
    end

    if @owner.nil?
      permissions = [User::Permissions::ADMIN, User::Permissions::SUPER_ADMIN]
      @owner = User.find_by(email: recipient_emails, permissions: permissions)
    end
  end

  def define_sender
    @from_address = @email.from[:email]
    if address_includes_forwarding_domain?
      email_address = retrieve_forwarder_email
      permissions = [User::Permissions::NONE, User::Permissions::INSTRUCTOR]
      @sender = User.find_by(email: email_address, permissions: permissions)
    elsif @from_address
      @sender = User.find_by(email: @from_address)
    end
  end

  def define_course
    @course = @sender.courses.last if @sender
  end

  def from_signature(from)
    ''"

    From #{from[:full]}
    "''
  end

  def define_content_and_reference_id
    @content = address_includes_forwarding_domain? ? @email.raw_body : @email.body
    reference = @email.raw_body.match('ref_(.*)_ref')
    @reference_id = reference[1] if reference
  end

  def address_includes_forwarding_domain?
    @from_address.end_with?(ENV['TICKET_FORWARDING_DOMAIN'])
  end

  def dispense_or_thread_ticket
    if @reference_id
      thread_ticket
    else
      create_ticket
    end
  rescue StandardError
    create_ticket
  end

  def create_ticket
    TicketDispenser::Dispenser.call(
      content: @content,
      owner_id: @owner&.id,
      project_id: @course&.id,
      sender_id: @sender&.id,
      subject: @email.subject,
      sender_email: @from_address
    )
  end

  def thread_ticket
    TicketDispenser::Dispenser.thread(
      content: @content,
      reference_id: @reference_id,
      sender_id: @sender&.id,
      sender_email: @from_address,
      subject: @email.subject
    )
  end
end
