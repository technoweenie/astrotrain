module Merb
  module GlobalHelpers
    def ensure_admin
      throw :halt, '<h1>No Entrar</h1>' unless admin?
    end
    
    def admin?
      session.authenticated? && session.user.admin?
    end
  end
end
