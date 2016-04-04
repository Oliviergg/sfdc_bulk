Rails.application.routes.draw do

  mount SfdcBulk::Engine => "/sfdc_bulk"
end
