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
    $scope.eci = $window.location.search.substring(1);


    $scope.initProfile = function(){
      var aURL = 'http://localhost:8080/sky/cloud/'+$scope.eci+'/sensor_profile/profile';
      return $http.post(aURL).success(function(data){
        $scope.number=data.number;
        $scope.name=data.name;
        $scope.location=data.location;
        $scope.threshold=data.threshold;
      })
    }
    $scope.initProfile();

    var bURL = 'http://localhost:8080/sky/event/'+$scope.eci+'/eid/sensor/profile_updated';
    $scope.changeProfile = function() {
      var pURL = bURL + "?number=" + $scope.number + "&name=" + $scope.name + "&location=" + $scope.location + "&threshold=" + $scope.threshold;
      return $http.post(pURL).success(function(data){
        $scope.initProfile();
      });
    };
  }
]);