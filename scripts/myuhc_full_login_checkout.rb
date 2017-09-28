require 'selenium-webdriver'
require 'rspec'
require 'json'
require 'colorize'
require 'io/console'
include RSpec::Matchers

# HSID Checkout: MyUHC Full Login

def setup
  caps = Selenium::WebDriver::Remote::Capabilities.new
	caps['browser'] = 'Firefox'
  @driver = Selenium::WebDriver.for :remote, url: "http://localhost:8001", :desired_capabilities => caps
#  @driver = Selenium::WebDriver.for :firefox
	@driver.manage.timeouts.implicit_wait = 10
end

def timestamp
    Time.now.strftime '[%Y-%m-%d %H:%M:%S] '
end

def validate_security_questions
	@questions = {
		"What is your favorite color?" => ENV['FAVORITE_COLOR'],
		"What was your first phone number?" => ENV['PHONE_NUMBER'],
		"What is your best friend's name?" => ENV['BEST_FRIEND']
	}

	@questions.each do |k,v|
		if v.nil?
			puts timestamp + "Set your environment variables! RTFM!".red
			abort
		end
	end
end

def myuhc_full_login
  puts timestamp + "Beginning MyUHC Full Login Checkout (VBF2)".green
	@driver.get 'http://www.myuhc.com'

	uname = @driver.find_element(:id, "hsid-username")
	pwd = @driver.find_element(:id, "hsid-password")
  login_submit = @driver.find_element(:id, "hsid-submit")
	
	puts timestamp + "We made it to myuhc.com, attempting a login.".green

	uname.send_keys 'tabaker78'
	pwd.send_keys ENV['HSID_PWD']
	login_submit.click


  question = @driver.find_element(:id, "authQuestiontextLabelId").text 
  rba_submit = @driver.find_element(:id, "continueSubmitButton")
	answer = @questions[question]

	if @driver.current_url.eql? 'https://rba.healthsafe-id.com/aa-web/evaluate?execution=e1s2&action=securityQuestion'
		puts timestamp + 'Login successful! Navigating to MyUHC portal!'.green
	else
		puts timestamp + "We didn't make it past RBA... :(".red
		teardown
		abort
	end
  
	@driver.find_element(:id, "challengeQuestionList[0].userAnswer").send_keys answer
  rba_submit.click

	if @driver.find_element(:name, "updateEmailAddressForm").nil?
		puts timestamp + "Failed to make it into myuhc.com. :(".red
	else
		puts timestamp + "MyUHC Login Checkout is successful!".green
		teardown
	end
end

def teardown
	@driver.quit
end

def run
  validate_security_questions
	setup
	yield
#	teardown
end

run do
	myuhc_full_login
end
