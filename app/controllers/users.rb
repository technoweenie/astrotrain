class Users < Application
  before :ensure_authenticated
  before :ensure_admin
  
  def index
    @users = User.all
    render
  end
  
  def show(id)
    @user = User.get(id)
    raise NotFound unless @user
    @mappings = @user.mappings
    render
  end
  
  def new
    @user = User.new
    render
  end

  def create(user)
    @user = User.new(user)
    if @user.save
      redirect url(:users), :message => {:notice => "User was successfully created"}
    else
      render :new
    end
  end
  
  def edit(id)
    @user = User.get(id)
    raise NotFound unless @user
    render
  end

  def update(user)
    @user = User.get(params[:id])
    raise NotFound unless @user
    if @user.update_attributes(user)
      redirect url(:users), :message => {:notice => "User was successfully updated"}
    else
      render :show
    end
  end

  def destroy(id)
    @user = User.get(id)
    raise NotFound unless @user
    if @user.destroy
      redirect url(:users)
    else
      raise InternalServerError
    end
  end
end