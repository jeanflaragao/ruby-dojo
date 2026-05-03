class User
  attr_reader :email, :name, :role
  
  def initialize(email:, name:, role: 'customer')
    @email = email
    @name = name
    @role = role
  end
  
  def admin?
    role == 'admin'
  end
  
  def guest?
    false
  end
  
  def discount_percentage
    case role
    when 'admin' then 100
    when 'vip' then 20
    else 0
    end
  end
end

# lib/models/guest_user.rb

class GuestUser
  def email
    'guest@example.com'
  end
  
  def name
    'Guest'
  end
  
  def role
    'guest'
  end
  
  def admin?
    false
  end
  
  def guest?
    true
  end
  
  def discount_percentage
    0
  end
end