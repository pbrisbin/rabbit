# when a search returns no results
class RabbitNotFoundError < StandardError;
end

# an error that should stop processing of that target only
class RabbitNonError < StandardError
end

# a build error on a dependecy must stop the processesing of its parent
# and any other deps left to build
class RabbitBuildError < StandardError
end

# an error that should stop us entirely
class RabbitError < StandardError
end
