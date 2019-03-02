var scrollbar, scrollbar2;
var map;

(function() {
    var lastTime = 0;
    var vendors = ['ms', 'moz', 'webkit', 'o'];
    for(var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
        window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
        window.cancelAnimationFrame = window[vendors[x]+'CancelAnimationFrame']
                                   || window[vendors[x]+'CancelRequestAnimationFrame'];
    }
 
    if (!window.requestAnimationFrame)
        window.requestAnimationFrame = function(callback, element) {
            var currTime = new Date().getTime();
            var timeToCall = Math.max(0, 16 - (currTime - lastTime));
            var id = window.setTimeout(function() { callback(currTime + timeToCall); },
              timeToCall);
            lastTime = currTime + timeToCall;
            return id;
        };
 
    if (!window.cancelAnimationFrame)
        window.cancelAnimationFrame = function(id) {
            clearTimeout(id);
        };
}());

window.onload = function() {
    scrollbar  = tinyscrollbar(document.getElementById("art"), {wheelSpeed: 10});
    scrollbar2  = tinyscrollbar(document.getElementById("projectlist"), {wheelSpeed: 10});
    loadGoogleMapsAPI(); 
}

function loadGoogleMapsAPI() {
  var script = document.createElement('script');
  script.type = 'text/javascript';
  script.src = 'https://maps.googleapis.com/maps/api/js?' +
      'callback=initMap';
  document.body.appendChild(script);
}

function initMap() {
    var mapCanvas = document.getElementById('detailsmap');
    mapCanvas.innerHTML = "";
    var latlng = new google.maps.LatLng(0,0);
    var mapOptions = {
        //backgroundColor: 'transparent',
        center: latlng,
        zoom: 1,
        zoomControl: true,
        zoomControlOptions: {
            style: google.maps.ZoomControlStyle.SMALL,
        },
        disableDoubleClickZoom: false,
        mapTypeControl: true,
        mapTypeControlOptions: {
            style: google.maps.MapTypeControlStyle.HORIZONTAL_BAR,
        },
        scaleControl: true,
        scrollwheel: true,
        panControl: false,
        streetViewControl: false,
        draggable : true,
        overviewMapControl: false,
        overviewMapControlOptions: {
            opened: false,
        },
        mapTypeId: google.maps.MapTypeId.HYBRID,
    }
    map = new google.maps.Map(mapCanvas, mapOptions);
}

function setMap(lat,lng,z) {
    map.setCenter(new google.maps.LatLng(lat,lng));
    map.setZoom(z);
    /*
    var marker = new google.maps.Marker({
      position: latlng,
      map: map,
      icon: 'icon.png',
      title: 'virtual tour'
    });
    marker.setAnimation(google.maps.Animation.BOUNCE);    
    */  
}

// (function(){
 
// var counter = 0,
// $items = document.querySelectorAll('.slideshow figure'),
// numItems = $items.length;
 
// var showCurrent = function(){
// var itemToShow = Math.abs(counter%numItems);
 
// [].forEach.call( $items, function(el){
// el.classList.remove('show');
// });
 
// $items[itemToShow].classList.add('show');
// };
 
// document.querySelector('.next').addEventListener('click', function() {
// counter++;
// showCurrent();
// }, false);
 
// document.querySelector('.prev').addEventListener('click', function() {
// counter--;
// showCurrent();
// }, false);
 
// })();

function initSlideshow(){
 
var counter = 0,
$items = document.querySelectorAll('.slideshow figure'),
numItems = $items.length;
 
var showCurrent = function(){
var itemToShow = Math.abs(counter%numItems);
 
[].forEach.call( $items, function(el){
el.classList.remove('show');
});
 
$items[itemToShow].classList.add('show');
};
 
document.querySelector('.next').addEventListener('click', function() {
counter++;
showCurrent();
}, false);
 
document.querySelector('.prev').addEventListener('click', function() {
counter--;
showCurrent();
}, false);
}