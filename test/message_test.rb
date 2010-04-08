require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

class MessageParsingTest < Test::Unit::TestCase
  test "bad content type header" do
    raw = mail(:bad_content_type)
    msg = Astrotrain::Message.parse(raw)

    expected_body = "--====boundary====\nContent-Type: text/plain; charset=\"us-ascii\"\n\nThis message is being generated automatically to notify you\nthat PowerMTA has crashed on mtasv.net.\n\nAs the information below is likely to be essential for debugging\nthe problem, please forward this message to <support@port25.com>.\nThank you.\n\n--====boundary====\nContent-Type: text/plain; charset=\"us-ascii\"\n\nYo\n--====boundary====--"
    expected_header = "multipart/mixed; boundary=\"====boundary=\"===\"\""

    assert_equal expected_body,   msg.body
    assert_equal expected_header, msg.headers['content-type']
  end

  test "basic email" do
    body = "---------- Forwarded message ----------\nblah blah"
    raw  = mail(:basic)
    msg  = Astrotrain::Message.parse(raw)

    assert_equal 'a16be7390810161014n52b603e9k1aa6bb803c6735aa@mail.gmail.com', msg.message_id
    expected = {'mime-version' => '1.0', 'content-type' => 'text/plain; charset=ISO-8859-1', 'to' => 'Processor <processor@astrotrain.com>',
      'x-custom' => 'reply', 'content-transfer-encoding' => '7bit', 'content-disposition' => 'inline', 'message-id' => '<a16be7390810161014n52b603e9k1aa6bb803c6735aa@mail.gmail.com>'}
    assert_equal expected, msg.headers

    assert_kind_of TMail::Mail, msg.mail

    assert_equal %w(processor@astrotrain.com), msg.recipients
    assert_equal %(Bob <user@example.com>),    msg.sender
    assert_equal 'Fwd: blah blah',             msg.subject
    assert_equal body,                         msg.body
    assert_equal raw,                          msg.raw
  end

  test "iso 8859 1 encoded headers" do
    raw = mail("iso-8859-1")
    msg = Astrotrain::Message.parse(raw)
    assert_equal %(Matthéw <user@example.com>), msg.sender
  end

  test "gb2312 encoded body" do
    raw = mail(:gb2312_encoding)
    msg = Astrotrain::Message.parse(raw)
    assert_equal "Dear Sirs, \r\nWe are given to understand that you are  Manufacturer of  plstic  Bottles\r\nAdd： blah China", 
      msg.body
  end

  test "gb2312 encoded body with invalid charset in mime version header" do
    raw = mail(:gb2312_encoding_invalid)
    msg = Astrotrain::Message.parse(raw)
    assert_equal "Dear Sirs, \r\nWe are given to understand that you are  Manufacturer of  plstic  Bottles\r\nAdd： blah China",
      msg.body
  end

  test "utf-8 encoded headers" do
    raw = mail('utf-8')
    msg = Astrotrain::Message.parse(raw)
    assert_equal %(isnard naiké <user@example.com>), msg.sender
  end

  test "multipart message with name property on Content Type" do
    raw = mail(:multipart)
    msg = Astrotrain::Message.parse(raw)

    assert_kind_of TMail::Mail, msg.mail

    assert_equal %w(foo@example.com), msg.recipients
    assert_equal "Testing out rich emails with attachments!\nThis one has a name property on Content-Type.\n[state:hold responsible:rick]\n\n",
      msg.body
    assert_equal 1,            msg.attachments.size
    assert_equal 'bandit.jpg', msg.attachments.first.filename
    assert_equal 'image/jpeg', msg.attachments.first.content_type
  end

  test "multipart message with filename property on Content Disposition" do
    raw = mail(:multipart2)
    msg = Astrotrain::Message.parse(raw)

    assert_kind_of TMail::Mail, msg.mail

    assert_equal %w(foo@example.com), msg.recipients
    assert_equal "Testing out rich emails with attachments!\nThis one has NO name property on Content-Type.\n[state:hold responsible:rick]\n\n",
      msg.body
    assert_equal 1,            msg.attachments.size
    assert_equal 'bandit.jpg', msg.attachments.first.filename
    assert_equal 'image/jpeg', msg.attachments.first.content_type
  end

  test "apple multipart message" do
    raw = mail(:apple_multipart)
    msg = Astrotrain::Message.parse(raw)

    assert_kind_of TMail::Mail, msg.mail

    assert_equal %w(foo@example.com), msg.recipients
    assert_equal "Let's have a test here:\r\n\r\n\r\n\nYum\r\n\r\n\r\nOn Feb 10, 2009, at 3:37 PM, Tender Support wrote:\r\n\r\n> // Add your reply above here\r\n> ==================================================\r\n> From: Tyler Durden\r\n> Subject: Email attachments and file upload\r\n>\r\n> not at the moment ... let me test\r\n>\r\n> View this Discussion online: http://foobar.com\r\n> .\r\n\r\n\r\n\r\n\r\n--Apple-Mail-7-451386929--", 
      msg.body
    assert_equal 1,           msg.attachments.size
    assert_equal 'logo.gif',  msg.attachments.first.filename
    assert_equal 'image/gif', msg.attachments.first.content_type
  end

  test "multiple sender/recipients" do
    body = "---------- Forwarded message ----------\nblah blah"
    raw  = mail(:multiple)
    msg  = Astrotrain::Message.parse(raw)

    assert_kind_of TMail::Mail,                                  msg.mail
    assert_equal %w(processor@astrotrain.com other@example.com), msg.recipients
    assert_equal %w(other@example.com processor@astrotrain.com), msg.recipients(%w(to original_to delivered_to))
    assert_equal %(user@example.com, boss@example.com),          msg.sender
    assert_equal 'Fwd: blah blah',                               msg.subject
    assert_equal body,                                           msg.body
    assert_equal raw,                                            msg.raw
  end

  test "recipients in the body" do
    raw = mail(:multiple_with_body_recipients)
    msg = Astrotrain::Message.parse(raw)

    assert_equal %w(processor@astrotrain.com other@example.com processor+foobar@astrotrain.com processor+blah@astrotrain.com), 
      msg.recipients
  end

  test "with only HTML body in a multipart message" do
    raw = mail(:html_multipart)
    msg = Astrotrain::Message.parse(raw)

    assert_equal '',                   msg.body
    assert_equal "<p>ABC</p>\n------", msg.html
  end

  test "with only HTML body in a multipart message" do
    raw = mail(:html)
    msg = Astrotrain::Message.parse(raw)

    assert_equal '',           msg.body
    assert_equal "<p>ABC</p>", msg.html
  end

  test "with X Original To header" do
    body = "---------- Forwarded message ----------\nblah blah"
    raw  = mail(:custom)
    msg  = Astrotrain::Message.parse(raw)

    assert_kind_of TMail::Mail, msg.mail
    assert_equal %w(processor-reply-57@custom.com processor-delivered@astrotrain.com processor@astrotrain.com), msg.recipients
    assert_equal %w(processor-delivered@astrotrain.com processor-reply-57@custom.com processor@astrotrain.com), msg.recipients(%w(delivered_to original_to to))
    assert_equal %w(processor@astrotrain.com processor-reply-57@custom.com processor-delivered@astrotrain.com), msg.recipients(%w(to original_to delivered_to))
    assert_equal %(user@example.com, boss@example.com), msg.sender
    assert_equal 'Fwd: blah blah',                      msg.subject
    assert_equal body,                                  msg.body
    assert_equal raw,                                   msg.raw
  end

  test "with multiple Delivered To headers" do
    raw     = mail(:multiple_delivered_to)
    msg = Astrotrain::Message.parse(raw)

    assert_equal %w(processor-reply-57@custom.com processor-delivered@astrotrain.com processor@astrotrain.com), msg.recipients
  end

  test "parsing invalid email collection" do
    assert_equal %w(ricky@foo.com bobby@foo.com), 
      Astrotrain::Message.parse_email_addresses("Ricky <ricky@foo.com>, Bobby:bobby@foo.com")
  end

  test "parsing invalid email" do
    assert_equal({:name => "Name", :email => "email@server.com"}, 
      Astrotrain::Message.parse_email_address("Name:email@server.com"))
  end

  test "parsing undisclosed recipients" do
    raw = mail(:undisclosed)
    m   = Astrotrain::Message.parse(raw)
    assert_equal(["undisclosed-recipients: ;"], m.recipients_from_to)
    assert_equal({:name => "undisclosed-recipients"}, Astrotrain::Message.parse_email_address(m.recipients_from_to.first))
  end
end