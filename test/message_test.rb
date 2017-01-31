# encoding: UTF-8
require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

class MessageParsingTest < Test::Unit::TestCase
  test "bad content type header" do
    msg = astrotrain :bad_content_type

    expected_body   = "This message is being generated automatically to notify you\nthat PowerMTA has crashed on mtasv.net.\n\nAs the information below is likely to be essential for debugging\nthe problem, please forward this message to <support@port25.com>.\nThank you.\n\nYo"
    expected_header = "multipart/mixed; boundary=\"====boundary====\""

    assert_equal expected_body,   msg.body
    assert_equal expected_header, msg.headers['content-type']
  end

  test "basic email" do
    body = "---------- Forwarded message ----------\nblah blah"
    msg  = astrotrain :basic

    assert_equal 'a16be7390810161014n52b603e9k1aa6bb803c6735aa@mail.gmail.com', msg.message_id
    expected = {'mime-version' => '1.0', 'content-type' => 'text/plain; charset=ISO-8859-1', 'date' => "Thu, 16 Oct 2008 10:14:18 -0700",
      'x-custom' => 'reply', 'content-transfer-encoding' => '7bit', 'content-disposition' => 'inline', 'message-id' => '<a16be7390810161014n52b603e9k1aa6bb803c6735aa@mail.gmail.com>'}
    assert_equal expected, msg.headers

    assert_kind_of Mail::Message, msg.mail

    assert_equal %w(processor@astrotrain.com), msg.recipients
    assert_equal %(Bob <user@example.com>),    msg.sender.join
    assert_equal %(Bob),                       msg.sender.first.display_name
    assert_equal %(user@example.com),          msg.sender.first.address
    assert_equal 'Fwd: blah blah',             msg.subject
    assert_equal body + "\n",                  msg.body
  end

  test "iso 8859 1 encoded headers" do
    msg = astrotrain "iso-8859-1"
    s   = Object.const_defined?(:Encoding) ? "Matthéw" :  "Matth\351w"
    assert_equal "user@example.com", msg.sender.first.address
    assert_equal "cc@example.com",   msg.cc.first.address
    assert_equal s,       msg.sender.first.display_name
    assert_equal s,       msg.cc.first.display_name
  end

  test "gb2312 encoded body" do
    msg = astrotrain(:gb2312_encoding)
    # encoding problem?
    # "Dear Sirs, \r\nWe are given to understand that you are  Manufacturer of  plstic  Bottles\r\nAdd： blah China"
    s = if Object.const_defined?(:Encoding)
      # ruby 1.9 is our bro
      "Dear Sirs, \r\nWe are given to understand that you are  Manufacturer of  plstic  Bottles\r\nAdd： blah China"
    else
      # ruby 1.8 gets messed up crap
      "Dear Sirs, \r\nWe are given to understand that you are  Manufacturer of  plstic  Bottles\r\nAdd\357\274\232 blah China"
    end
    assert_equal s, msg.body
    assert_mail_utf8 msg
  end

  test "gb2312 encoded body with invalid charset in mime version header" do
    msg = astrotrain(:gb2312_encoding_invalid)
    # encoding problem?
    # "Dear Sirs, \r\nWe are given to understand that you are  Manufacturer of  plstic  Bottles\r\nAdd： blah China"
    s = "Dear Sirs, \r\nWe are given to understand that you are  Manufacturer of  plstic  Bottles\r\nAdd?? blah China"
    assert_equal s, msg.body
    assert_mail_utf8 msg
  end

  test "utf-8 encoded headers" do
    msg = astrotrain('utf-8')
    assert_equal "isnard naik\303\251", msg.sender.first.display_name
    assert_equal "user@example.com",    msg.sender.first.address
  end

  test "multipart message with name property on Content Type" do
    msg = astrotrain(:multipart)

    assert_kind_of Mail::Message, msg.mail

    assert_equal %w(foo@example.com), msg.recipients
    assert_equal "Testing out rich emails with attachments!\nThis one has a name property on Content-Type.\n[state:hold responsible:rick]\n",
      msg.body
    assert_equal 1,            msg.attachments.size
    assert_equal 'bandit.jpg', msg.attachments.first.filename
    assert_match 'image/jpeg', msg.attachments.first.content_type
  end

  test "multipart message with filename property on Content Disposition" do
    msg = astrotrain(:multipart2)

    assert_kind_of Mail::Message, msg.mail

    assert_equal %w(foo@example.com), msg.recipients
    assert_equal "Testing out rich emails with attachments!\nThis one has NO name property on Content-Type.\n[state:hold responsible:rick]\n",
      msg.body
    assert_equal 1,            msg.attachments.size
    assert_equal 'bandit.jpg', msg.attachments.first.filename
    assert_match 'image/jpeg', msg.attachments.first.content_type
  end

  test "apple multipart message" do
    msg = astrotrain(:apple_multipart)

    assert_kind_of Mail::Message, msg.mail

    assert_equal %w(foo@example.com), msg.recipients
    assert_equal "Let's have a test here:\n\n\nYum\n\n\nOn Feb 10, 2009, at 3:37 PM, Tender Support wrote:\n\n> // Add your reply above here\n> ==================================================\n> From: Tyler Durden\n> Subject: Email attachments and file upload\n>\n> not at the moment ... let me test\n>\n> View this Discussion online: http://foobar.com\n> .\n\n\n\n",
      msg.body
    assert_equal 1,           msg.attachments.size
    assert_equal 'logo.gif',  msg.attachments.first.filename
    assert_match 'image/gif', msg.attachments.first.content_type
  end

  test "multiple sender/recipients" do
    body = "---------- Forwarded message ----------\nblah blah"
    msg  = astrotrain(:multiple)

    assert_kind_of Mail::Message,                                msg.mail
    assert_equal %w(processor@astrotrain.com other@example.com), msg.recipients
    assert_equal %w(other@example.com processor@astrotrain.com), msg.recipients(%w(to original_to delivered_to))
    assert_equal %(user@example.com),                            msg.sender[0].address
    assert_equal %(boss@example.com),                            msg.sender[1].address
    assert_equal 'Fwd: blah blah',                               msg.subject
    assert_equal body,                                           msg.body
  end

  test "recipients in the body" do
    msg = astrotrain(:multiple_with_body_recipients)

    assert_equal %w(processor@astrotrain.com other@example.com processor+foobar@astrotrain.com processor+blah@astrotrain.com),
      msg.recipients(Astrotrain::Message.recipient_header_order + %w(body))
  end

  test "with only HTML body in a multipart message" do
    msg = astrotrain(:html_multipart)

    assert_equal '',                   msg.body
    assert_equal "<p>ABC</p>\n------", msg.html
  end

  test "with only HTML body in a multipart message" do
    msg = astrotrain(:html)

    assert_equal '',           msg.body
    assert_equal "<p>ABC</p>", msg.html
  end

  test "with X Original To header" do
    body = "---------- Forwarded message ----------\nblah blah"
    msg  = astrotrain(:custom)

    assert_kind_of Mail::Message, msg.mail
    assert_equal %w(processor-reply-57@custom.com processor-delivered@astrotrain.com processor@astrotrain.com), msg.recipients
    assert_equal %w(processor-delivered@astrotrain.com processor-reply-57@custom.com processor@astrotrain.com), msg.recipients(%w(delivered_to original_to to))
    assert_equal %w(processor@astrotrain.com processor-reply-57@custom.com processor-delivered@astrotrain.com), msg.recipients(%w(to original_to delivered_to))
    assert_equal 'user@example.com', msg.sender[0].address
    assert_equal 'boss@example.com', msg.sender[1].address
    assert_equal 'Fwd: blah blah',   msg.subject
    assert_equal body,               msg.body
  end

  test "with multiple Delivered To headers" do
    msg = astrotrain(:multiple_delivered_to)

    assert_equal %w(processor-reply-57@custom.com processor-delivered@astrotrain.com processor@astrotrain.com), msg.recipients
  end

  test "parsing invalid email collection" do
    msg = astrotrain(:bad_email_format)
    assert_equal 'ricky.bobby@foo.com', msg.from[0].address
    assert_equal 'bobby@foo.com', msg.from[1].address
    assert_equal 2, msg.from.size
  end

  test "parsing undisclosed recipients" do
    msg = astrotrain(:undisclosed)
    assert_equal([], msg.recipients_from_to)
  end

  test "parsing emails from body" do
    msg = astrotrain :email_in_body
    assert_equal %w(foo@bar.com), msg.recipients_from_body.map(&:address)
  end

  test "saves path of parsed email" do
    path = mail(:basic)
    msg  = Astrotrain::Message.read(path)
    assert_equal path, msg.path
  end

  test "parses and transcodes email with utf-8" do
    path = mail(:utf8)
    msg = Astrotrain::Message.read(path)
    assert_mail_utf8 msg
  end

  test "deals with bad ascii" do
    path = mail(:bad_ascii)
    msg = Astrotrain::Message.read(path)
    assert_mail_utf8 msg
    assert msg.headers['message-id'].as_utf8.valid?
  end

  def assert_mail_utf8(mail)
    [:html, :body].each do |attr|
      str = mail.send(attr)
      assert str.as_utf8.valid?
      if str.respond_to?(:encoding)
        assert_equal "UTF-8", str.encoding.name
      end
    end
  end
end
