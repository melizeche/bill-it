# encoding: UTF-8
require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe BillsController do

  # This should return the minimal set of attributes required to create a valid
  # Bill. As you add validations to Bill, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    { "uid" => "MyString" }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # BillsController. Be sure to keep this updated too.
  def valid_session
    {}
  end

  describe "filter_conditions" do
    it "passes 'q' params" do
      conditions = {"q" => "Pena"}
      filtered_conditions = BillsController.new.filter_conditions(conditions)
      expect(filtered_conditions[:equivalence_conditions]).to eq(conditions)
    end
    
    context "with bill attributes as params" do
      it "passes bill attributes" do
        mongoid_attribute_names = ["_id", "created_at", "updated_at"]
        attr1, attr2 = (Bill.attribute_names - mongoid_attribute_names)[0..1]
        conditions = {attr1 => "Pena", attr2 => "1234-5"}
        filtered_conditions = BillsController.new.filter_conditions(conditions)
        expect(filtered_conditions[:equivalence_conditions]).to eq(conditions)
      end

      it "passes range params" do
        range_modifier_min = "_min" #This should be a global variable for the rails project
        bill_range_fields = Bill.fields.dup
        bill_range_fields.reject! {|field_name, metadata| metadata.options[:type]!= Time}
        attr1 = bill_range_fields.keys[0] + range_modifier_min
        conditions = {attr1 => "2008-08-11T00:00:00Z"}
        return_conditions = {bill_range_fields.keys[0] => "2008-08-11T00:00:00Z"}
        filtered_conditions = BillsController.new.filter_conditions(conditions)
        expect(filtered_conditions[:range_conditions_min]).to eq(return_conditions)
      end
    end
    
    context "given unwanted params" do
      it "filters nil values and empty strings" do
        mongoid_attribute_names = ["_id", "created_at", "updated_at"]
        attr1, attr2 = (Bill.attribute_names - mongoid_attribute_names)[0..1]
        conditions = {attr1 => "", attr2 => nil}
        filtered_conditions = BillsController.new.filter_conditions(conditions)
        for key, val in filtered_conditions
          expect(val).to be_empty
        end
      end

      it "filters unknown attributes" do
        conditions = {"wia9nai4OS0iXiif" => "Pena"}
        filtered_conditions = BillsController.new.filter_conditions(conditions)
        for key, val in filtered_conditions
          expect(val).to be_empty
        end
      end

      it "filters mongoid attributes" do
        conditions = {"_id" => "1234567890"}
        filtered_conditions = BillsController.new.filter_conditions(conditions)
        for key, val in filtered_conditions
          expect(val).to be_empty
        end
      end
    end
  end

  describe "GET show" do
    describe "with existing id" do
      it "assigns the requested bill as @bill" do
        bill = FactoryGirl.create(:bill1)
        get :show, id: bill.uid, format: :json
        assigns(:bill).should eq(bill)
      end

      it "returns the correct bill in json format" do
        bill = FactoryGirl.create(:bill1)
        get :show, id: bill.uid, format: :json
        response.should be_success
        response.body.should eq(assigns(:bill).to_json)
      end
    end
    describe "with non existent id" do
      it "returns a 404" do
        bill = FactoryGirl.create(:bill1)
        @bill3 = FactoryGirl.attributes_for(:bill3)
        get :show, id: @bill3[:uid], format: :json
        response.response_code.should == 404
      end
    end
  end

  describe "GET search" do

    before(:each) do
      @bill1 = FactoryGirl.create(:bill1)
      @bill2 = FactoryGirl.create(:bill2)
      @bill3 = FactoryGirl.create(:bill3)
      @bill4 = FactoryGirl.create(:bill4)
      stub_request(:any, "http://www.leychile.cl/Consulta/obtxml?opt=7&idLey=19029").
        to_return(:body => File.open("#{Rails.root}/spec/example_files/ley_19029.xml"), :status => 200)
      stub_request(:any, "http://www.senado.cl/appsenado/index.php?mo=tramitacion&ac=getDocto&iddocto=202&tipodoc=compa").
        to_return(:body => File.open("#{Rails.root}/spec/example_files/boletin_3773-06.doc"), :status => 200)
      Sunspot.remove_all(Bill)
      Sunspot.index!(Bill.all)
    end

    context "doing a simple 'q' query" do
      context "with a single result" do
        it "assigns query results to @bills" do
          get :search, q: "Aeronáutico", format: :json
          assigns(:bills).should eq([@bill1])
        end

        #FIX works well, but haven't found the way to test the format
        xit "returns bills in roar/json format" do
          get :search, q: "Tramitación", format: :json
          response.body.should eq(assigns(:bills).to_json)
        end
      end

      context "with multiple results" do
        it "assigns multiple query results to @bills" do
          get :search, q: "transparencia", format: :json
          assigns(:bills).should eq([@bill3, @bill4])
        end

        it "paginates results" do
          get :search, q: "", per_page: '2', page: '1', format: :json
          first_page = assigns(:bills)
          get :search, q: "", per_page: '2', page: '2', format: :json
          second_page = assigns(:bills)
          first_page.length.should eq(2)
          second_page.length.should eq(2)
          first_page.should_not eq second_page
        end

        it "boosts results for fields: tag, subject_areas, title and abstract, in that order" do
          bill1 = FactoryGirl.create(:bill, uid: 1, abstract: "term")
          bill2 = FactoryGirl.create(:bill, uid: 2, title: "term")
          bill3 = FactoryGirl.create(:bill, uid: 3, subject_areas: ["term"])
          bill4 = FactoryGirl.create(:bill, uid: 4, tags: ["term"])
          Sunspot.remove_all(Bill)
          Sunspot.index!(Bill.all)
          get :search, q: "term", format: :json
          assigns(:bills).should eq([bill4, bill3, bill2, bill1])
        end
      end

      context "in referenced documents" do
        it "searches over xml" do
          get :search, q: "presidio", format: :json
          assigns(:bills).should eq([@bill1, @bill2])
        end

        it "searches over doc" do
          get :search, q: "apruébase", format: :json
          assigns(:bills).should eq([@bill3, @bill4])
        end
      end
    end

    context "advanced query" do
      it "assigns query results to @bills" do
        get :search, abstract: "transparencia", initial_chamber: "C.Diputados", format: :json
        assigns(:bills).should eq([@bill4])
      end

      it "searches over a date range" do
        get :search, publish_date_min: "2008-01-01T00:00:00Z", publish_date_max: "2010-01-01T00:00:00Z",\
          initial_chamber: "Senado", format: :json
        assigns(:bills).should eq([@bill3])
      end

      it "matches bill identifiers with and without the trailing numbers" do
        get :search, bill_id: "3773", format: :json
        assigns(:bills).should eq([@bill3])
        get :search, bill_id: "3773-06", format: :json
        assigns(:bills).should eq([@bill3])
      end

      it "searches over bill functions" do
        get :search, law_text: "presidio", format: :json
        assigns(:bills).should eq([@bill1, @bill2])
      end

      it "searches for bill authors with name and last name in any order" do
        get :search, authors: "Gazmuri Mujica Jaime", format: :json
        assigns(:bills).should eq([@bill3])
        get :search, authors: "Jaime Gazmuri Mujica", format: :json
        assigns(:bills).should eq([@bill3])
      end

      it "searches with OR operator" do
        get :search, tags: "justicia|transparencia", format: :json
        assigns(:bills).should eq([@bill1,@bill2,@bill3, @bill4])
      end

      it "searches by priorities" do
        Date.stub(:today){"2014-01-13".to_date}
        priority1 = FactoryGirl.create(:priority1, type: "Simple", entry_date: Date.today - 1)
        priority2 = FactoryGirl.create(:priority1, type: "Discusión inmediata", entry_date: Date.today - 1)
        priority3 = FactoryGirl.create(:priority1, type: "Suma", entry_date: Date.today - 1)
        priority4 = FactoryGirl.create(:priority1, type: "Discusión inmediata", entry_date: Date.today - 1)
        @bill1.priorities = [priority1]
        @bill2.priorities = [priority2]
        @bill3.priorities = [priority3]
        @bill4.priorities = [priority4]
        @bill1.save
        @bill2.save
        @bill3.save
        @bill4.save
        Sunspot.remove_all(Bill)
        Sunspot.index!(@bill1)
        Sunspot.index!(@bill2)
        Sunspot.index!(@bill3)
        Sunspot.index!(@bill4)
        Sunspot.commit
        get :search, current_priority: "Discusión inmediata", format: :json
        assigns(:bills).should eq([@bill2,@bill4])
      end
    end
  end

  describe "feed" do
    it "receives a bill id and returns last update date" do
      @bill1 = FactoryGirl.create(:bill1)
      get :feed, id: @bill1.uid
      assigns(:updated_at).to_s.should eq(@bill1.updated_at.to_s)
    end 
  end

  describe "GET index" do
    xit "assigns all bills as @bills" do
      bill = Bill.create! valid_attributes
      get :index, {}, valid_session
      assigns(:bills).should eq([bill])
    end
  end

  describe "GET new" do
    xit "assigns a new bill as @bill" do
      get :new, {}, valid_session
      assigns(:bill).should be_a_new(Bill)
    end
  end

  describe "GET edit" do
    xit "assigns the requested bill as @bill" do
      bill = Bill.create! valid_attributes
      get :edit, {:id => bill.to_param}, valid_session
      assigns(:bill).should eq(bill)
    end
  end

  #Modified the params create gets so they're compatible with ROAR's Model.post
  #and don't know how to simulate them with rspec
  describe "POST create" do
    before { pending }
    describe "with valid params" do
      it "creates a new Bill" do
        @bill1 = FactoryGirl.build(:bill1)
        expect {
          post :create, format: :json, :bill => @bill1
        }.to change(Bill, :count).by(1)
      end

      it "assigns a newly created bill as @bill" do
        @bill1 = FactoryGirl.build(:bill1)
        post :create, format: :json, :bill => @bill1
        assigns(:bill).should be_a(Bill)
        assigns(:bill).should be_persisted
      end

      it "responds with the created bill" do
        @bill1 = FactoryGirl.build(:bill1)
        post :create, format: :json, :bill => @bill1
        response.should be_success
        response.body.should eq(assigns(:bill).to_json)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved bill as @bill" do
        # Trigger the behavior that occurs when invalid params are submitted
        # Eventually useful for form feedback
        Bill.any_instance.stub(:save).and_return(false)
        post :create, format: :json, :bill => { "uid" => "invalid value" }
        assigns(:bill).should be_a_new(Bill)
      end

      xit "responds with the rejected params" do
        # Trigger the behavior that occurs when invalid params are submitted
        Bill.any_instance.stub(:save).and_return(false)
        post :create, format: :json, :bill => { "uid" => "invalid value" }.to_json
        response.should eq(assigns(:bill_error).to_json)
      end
    end

    it "indexes the new bill after creation" do
      @bill1 = FactoryGirl.build(:bill1)
      post :create, format: :json, bill: @bill1
      get :search, bill_id: "1-07", format: :json
      assigns(:bills).first.uid.should eq(bill1.uid)
    end
  end

  #Modified the params update gets so they're compatible with ROAR's Model.post
  #and don't know how to simulate them with rspec
  describe "PUT update" do
    before { pending }
    describe "with valid params" do
      it "updates the requested bill" do
        bill = FactoryGirl.create(:bill1)
        bill_new_attrs = FactoryGirl.attributes_for(:bill3)
        bill_new_attrs.delete(:uid)
        bill_new_attrs.delete(:title)
        put :update, format: :json, :id => bill.uid, :bill => bill_new_attrs
        bill_new_attrs.keys.each do |key|
          assigns(:bill)[key].should eq(bill_new_attrs[key])
        end
      end

      it "doesn't modify the rest of the bill's attributes" do
        bill = FactoryGirl.create(:bill1)
        bill_attrs = bill.attributes
        bill_new_attrs = FactoryGirl.attributes_for(:bill3)
        bill_new_attrs.delete(:uid)
        bill_new_attrs.delete(:title)
        put :update, format: :json, :id => bill.uid, :bill => bill_new_attrs
        attrs_not_updated = assigns(:bill).attributes.keys - bill_new_attrs.keys.map {|x| x.to_s}
        attrs_not_updated.each do |key|
          #FIX It doesn't work for time attributes for some reason
          next if key == 'created_at' || key == 'updated_at' 
          bill.attributes[key].should eq(bill_attrs[key])
        end
      end

      it "assigns the requested bill as @bill" do
        bill = FactoryGirl.create(:bill1)
        bill_new_attrs = FactoryGirl.attributes_for(:bill3)
        bill_new_attrs.delete(:uid)
        bill_new_attrs.delete(:title)
        put :update, format: :json, :id => bill.uid, :bill => bill_new_attrs
        assigns(:bill).should eq(bill)
      end
    end

    #FIX Manage invalid id or params
    describe "with invalid params" do
      xit "assigns the bill as @bill" do
        bill = FactoryGirl.create(:bill1)
        bill_new_attrs = FactoryGirl.attributes_for(:bill3)
        # Trigger the behavior that occurs when invalid params are submitted
        Bill.any_instance.stub(:save).and_return(false)
        put :update, format: :json, :id => bill_new_attrs[:uid], :bill => bill_new_attrs.to_json
        assigns(:bill).should eq(bill)
      end

     xit "re-renders the 'edit' template" do
        bill = Bill.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Bill.any_instance.stub(:save).and_return(false)
        put :update, {:id => bill.to_param, :bill => { "uid" => "invalid value" }}, valid_session
        response.should render_template("edit")
      end
    end

    it "indexes the changes to the bill after update" do
      @bill1 = FactoryGirl.create(:bill1)
      @bill1.title = "changedbilltitle"
      put :update, format: :json, id: @bill1.uid, bill: @bill1
      get :search, title: "changedbilltitle", format: :json
      assigns(:bills).first.uid.should eq(@bill1.uid)
    end
  end

  describe "DELETE destroy" do
    xit "destroys the requested bill" do
      bill = Bill.create! valid_attributes
      expect {
        delete :destroy, {:id => bill.to_param}, valid_session
      }.to change(Bill, :count).by(-1)
    end

    xit "redirects to the bills list" do
      bill = Bill.create! valid_attributes
      delete :destroy, {:id => bill.to_param}, valid_session
      response.should redirect_to(bills_url)
    end
  end

  describe "last_update" do
    it "returns the update date of the bill that was most recently updated" do
      @bill1 = FactoryGirl.create(:bill1)
      @bill1_last_update = @bill1.updated_at.strftime("%d/%m/%Y")
      get :last_update
      assigns(:date).should eq(@bill1_last_update)
    end
  end

end
