angular.module('timing', [])
.directive('focusInput', function($timeout) {
  return {
    link: function(scope, element, attrs) {
      element.bind('click', function() {
        $timeout(function() {
          element.parent().find('input')[0].focus();
        });
      });
    }
  };
})
.controller('MainCtrl', [
  '$scope','$http','$window',
  function($scope,$http,$window){
    $scope.timings = [];
    $scope.violations = [];
    $scope.most_recent_temp = '444';
    $scope.eci = $window.location.search.substring(1);
 
    var gURL = 'http://localhost:8080/sky/cloud/'+$scope.eci+'/temperature_store/temperatures';
    $scope.getAll = function() {
      $http.get('http://localhost:8080/sky/cloud/'+$scope.eci+'/temperature_store/threshold_violations').success(function(data){
        angular.copy(data, $scope.violations);
      });
      return $http.get(gURL).success(function(data){
        // angular.copy(data[data.length - 1].temperature, $scope.most_recent_temp)
        $scope.most_recent_temp = data[data.length - 1].temperature // works for now 🤷
        // console.log(data[data.length - 1].temperature)
        angular.copy(data, $scope.timings);
        
      });
    };
 
    $scope.getAll();
  }
]);