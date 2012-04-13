require 'test/test_helper'

class SubscriptionsTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include TestHelper::Methods


  # subscribing to new things -
  # identical parameters to search, it should be easy to get a one to one mapping
  # between the two, and to lookup whether a search has already been subscribed to
  def test_subscribe_to_searches_by_plain_keyword
    user = new_user!
    query = "environment"
    query2 = "copyright"
    
    assert_equal 0, user.subscriptions.count
    assert_equal 0, user.interests.count

    post "/subscriptions", {:subscription_type => "federal_bills", :query => query}, login(user)
    assert_response 200

    assert_equal 1, user.subscriptions.count
    assert_equal 1, user.interests.count

    assert_equal query, user.interests.first.in
    assert_equal query, user.subscriptions.first.interest_in
    assert_equal "federal_bills", user.subscriptions.first.subscription_type

    post "/subscriptions", {:subscription_type => "state_bills", :query => query}, login(user)
    assert_response 200

    assert_equal 2, user.subscriptions.count
    assert_equal 1, user.interests.count

    post "/subscriptions", {:subscription_type => "state_bills", :query => query2}, login(user)
    assert_response 200

    assert_equal 3, user.subscriptions.count
    assert_equal 2, user.interests.count

    # posting the same subscription should return 200, but be idempotent - nothing changed
    post "/subscriptions", {:subscription_type => "state_bills", :query => query2}, login(user)
    assert_response 200

    assert_equal 3, user.subscriptions.count
    assert_equal 2, user.interests.count

    # but if we include filter data, it's different!
    post "/subscriptions", {:subscription_type => "state_bills", :query => query2, :state_bills => {:state => "DE"}}, login(user)
    assert_response 200

    assert_equal 4, user.subscriptions.count
    assert_equal 2, user.interests.count

    # but, that data is also taken into account when finding duplicates
    post "/subscriptions", {:subscription_type => "state_bills", :query => query2, :state_bills => {:state => "DE"}}, login(user)
    assert_response 200

    assert_equal 4, user.subscriptions.count
    assert_equal 2, user.interests.count
  end

  def test_unsubscribe_from_individual_searches
    # interest 1 has subscription 1 and subscription 2
    # interest 2 has subscription 1
    # unsubscribe from interest 1, subscription 1, verify interest 1 is intact
    # unsubscribe from interest 1, subscription 2, verify interest 1 is gone
    # unsubscribe from interest 2, subscription 1, verify interest 2 is gone
  end

  # Eventually: tests on subscriptions with no keyword at all

  def test_follow_item
    # subscribe to item 1, verify new interest created with all subscriptions
  end

  def test_unfollow_item
    # subscribe to item 1
    # unsubscribe from item 1, verify interest destroyed, along with all subscriptions
  end

  # tragic
  def test_destroy_search_interest
    user = new_user!
    query = "environment"
    interest = user.interests.create! :in => query, :interest_type => "search"
    s1 = interest.subscriptions.create! :subscription_type => "federal_bills", :user_id => user.id, :interest_in => query
    s2 = interest.subscriptions.create! :subscription_type => "state_bills", :user_id => user.id, :interest_in => query

    delete "/interest/#{interest.id}", {}, login(user)
    assert_equal 200, last_response.status

    assert_nil Interest.find(interest.id)
    assert_nil Subscription.find(s1.id)
    assert_nil Subscription.find(s2.id)
  end

  def test_destroy_search_interest_not_users_own
    user = new_user!
    query = "environment"
    interest = user.interests.create! :in => query, :interest_type => "search"
    s1 = interest.subscriptions.create! :subscription_type => "federal_bills", :user_id => user.id, :interest_in => query
    s2 = interest.subscriptions.create! :subscription_type => "state_bills", :user_id => user.id, :interest_in => query

    user2 = new_user! :email => user.email.succ

    delete "/interest/#{interest.id}", {}, login(user2)
    assert_equal 404, last_response.status

    assert_not_nil Interest.find(interest.id)
    assert_not_nil Subscription.find(s1.id)
    assert_not_nil Subscription.find(s2.id)
  end

  def test_destroy_search_interest_not_logged_in
    user = new_user!
    query = "environment"
    interest = user.interests.create! :in => query, :interest_type => "search"
    s1 = interest.subscriptions.create! :subscription_type => "federal_bills", :user_id => user.id, :interest_in => query
    s2 = interest.subscriptions.create! :subscription_type => "state_bills", :user_id => user.id, :interest_in => query

    user2 = new_user! :email => user.email.succ

    delete "/interest/#{interest.id}"
    assert_equal 302, last_response.status

    assert_not_nil Interest.find(interest.id)
    assert_not_nil Subscription.find(s1.id)
    assert_not_nil Subscription.find(s2.id)
  end

  def test_update_interest_delivery_type

  end

  def test_update_interest_not_users_own
  end

  def test_update_interest_not_logged_in
  end

end