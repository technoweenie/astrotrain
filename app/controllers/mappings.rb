class Mappings < Application
  before :ensure_authenticated

  def index
    @mappings = session.user.mappings
    render
  end

  def show(id)
    @mapping = session.user.mappings.get(id)
    raise NotFound unless @mapping
    render
  end

  def new
    @mapping = Mapping.new
    render
  end

  def edit(id)
    @mapping = session.user.mappings.get(id)
    raise NotFound unless @mapping
    render
  end

  def create(mapping)
    @mapping = session.user.mappings.build(mapping)
    if @mapping.save
      redirect resource(@mapping), :message => {:notice => "Mapping was successfully created"}
    else
      render :new
    end
  end

  def update(mapping)
    @mapping = session.user.mappings.get(mapping[:id])
    raise NotFound unless @mapping
    if @mapping.update_attributes(mapping)
       redirect resource(@mapping)
    else
      render :edit
    end
  end

  def destroy(id)
    @mapping = session.user.mappings.get(id)
    raise NotFound unless @mapping
    if @mapping.destroy
      redirect resource(@mappings)
    else
      raise InternalServerError
    end
  end

end
