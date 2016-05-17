module SfdcBulk
  class SfdcQueryApi 
    include SfdcBulkQueryConfig
    include SfdcBulkQueryApi
    include SfdcSoqlBuilder
    include SfdcBulkApiBase

  end
end