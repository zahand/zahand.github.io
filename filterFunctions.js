var masterFilter = newFilter();
var searchFilter;
var VFilter = false;
var filterOn = false;
var projects;
var projectList;
var p5;

/*
function makeDL() {
	var projex = [];
	for (var i=0; i<projects.length; i++) {
		var p = projects[i];
		projex.push(
			{
				"name":p.name,
				"year":2017,
				"x":p.x,
				"y":p.y,
				"lat":p.N,
	            "lng":p.E,
	            "zoom":12,
				"desc":p.details[0],
	            "client":p.details[1],
	            "scope":p.details[2],
	            "location":p.details[3],
	            "capacity":p.details[4],
	            "partner":p.details[5],
	            "tech":p.details[6],
	            "date":p.details[7],
	            "status":p.details[8],
				"external":p.details[9],
				"tour":p.details[10],
				"filter":p.filter			
			}
		);		
	}
    var textToWrite = JSON.stringify(projex);
    var textFileAsBlob = new Blob([textToWrite], {type:"text/plain"});
    var fileNameToSaveAs = "data.json";

    var downloadLink = document.getElementById("nargan");
    downloadLink.download = fileNameToSaveAs;
    downloadLink.href = window.URL.createObjectURL(textFileAsBlob);
}   
*/

function enter() {
  var m = document.getElementById("message");
  m.setAttribute("onclick", "document.getElementById('welcome').className='hid'");  
  m.className = "enter";
  m.innerHTML = "Click Here to Enter";
  m = document.getElementById("dot");
  m.addEventListener("webkitAnimationIteration", endDotAnim);
  m.addEventListener("animationiteration", endDotAnim);
  // p5 = Processing.instances[0];	
  p5 = Processing.getInstanceById(getProcessingSketchId());
  //p5.loadProjectz(projects);
}

function endDotAnim(){
    document.getElementById("dot").className = "";
}

function newFilter() {
	var f = [];
	for (var i=0; i<11; i++){
		f[i] = true;
	}
	return f;
}

function zoomInP5(){
	p5.zoomIn();
	p5.sLoop();	
}
function zoomOutP5(){
	p5.zoomOut();
	p5.sLoop();	
}
function zoomExtP5(){
	p5.zoomExt();
	p5.sLoop();	
}

function checkMult(start,end){
	var form = document.getElementById('checkform');
	var alltrue = true;
	for(var i=start; i<=end; i++){
		if (form.filterToggle[i].checked == false) alltrue = false;
	}
	if (alltrue) {
		for(var i=0; i<11; i++){
			if (i >= start && i <= end) continue;
			if (form.filterToggle[i].checked) alltrue = false; 
		}
	}
	for(var i=0; i<11; i++){
		var bool = false;
		if ((i >= start && i <= end) || alltrue) bool = true;
		form.filterToggle[i].checked=bool;
		masterFilter[i]=bool;
	}
	var chkm = form.CheckMult;
	if (start == 0 && end == 10) start = -1;
	for(var i=0; i<chkm.length; i++){
		if (chkm[i].value == start) chkm[i].checked = chkm[i].checked;
		else chkm[i].checked = false;
	}
	filterOn = false;
	for(var i=0; i<11; i++){
		if (form.filterToggle[i].checked == false) filterOn = true;
	}	
	p5.filterProjects();	
}
function checkThis(value,checked){
	var form = document.getElementById('checkform');
	var allfalse = true;
	for(var i=0; i<11 ; i++){
		if (i == value) continue;
		if (form.filterToggle[i].checked) allfalse = false;
	}
	for(var i=0; i<11; i++){
		var bool = false;	
		if (allfalse || i==value) bool = true;
		masterFilter[i] = bool;
		form.filterToggle[i].checked = bool;
	}
	var chkm = form.CheckMult;
	for(var i=0; i<chkm.length; i++){
		chkm[i].checked = false;
	}	
	filterOn = false;
	for(var i=0; i<11; i++){
		if (form.filterToggle[i].checked == false) filterOn = true;
	}	
	p5.filterProjects();
}

function linkProjectP5(elem, pid, bool) {
	p5.linkToList(elem,pid,bool);
	p5.sLoop();
}
function linkCatP5(elem) {
	p5.linkToCat(elem, true);
	p5.sLoop();
}
function linkCatP5Mult(elem) {	
	var subs = elem.parentNode.getElementsByClassName("toggle");
	for (var i = 0; i < subs.length; i++) {
		p5.linkToCat(subs[i], false);
	}
	p5.sLoop();
}
function toggleVP5(bool){
	VFilter = bool;
	p5.filterProjects();
}
function highlightVP5(bool) {
	p5.highlightV(bool);
	p5.sLoop();
}
function toggleMapP5(bool){
	p5.toggleMap(bool);
	p5.sLoop();	
}
function toggleFieldsP5(value, bool){
	p5.toggleFields(value, bool);
	p5.sLoop();	
}
function highlightFieldsP5(value){
	p5.highlightFields(value);
	p5.sLoop();	
}

function closeDetails(){
	p5.selectProject(null);
}
function launchDetails(elem, pid){
	p5.selectProject(projects[pid]);
	linkProjectP5(elem,pid,false);
}

function populateList(){
	var options = {
	  valueNames: [ 'name', 'year' ],
	  item: '<li></li>'
	};
	projectList = new List('menu2', options);
	searchFilter = [];
	for(var i=0; i<projects.length; i++){
		searchFilter.push(true);
		projectList.add({
			name: projects[i].name,
			year: projects[i].y,
			pid: projects[i].pid
		});
		var id = projects[i].pid;
		var brokenName = (projects[i].name).replace("(", "<small>(");
		brokenName.replace(")", ")</small>");
		// brokenName = "&#8226 " + brokenName;
		projectList.items[i].elm.innerHTML = 
			'<h3 onclick="launchDetails(this,'+id+')" onmouseover="linkProjectP5(this,'+id+',true)" onmouseout="linkProjectP5(this,'+id+',false)">'+brokenName+'</h3>';
	}	
	projectList.on("updated", function(){scrollbar2.update()});	
	projectList.sort('name', { order: "asc" });
	projectList.search('', ['name']);
	
	projectList.on("searchComplete", function(){
		var searchEmpty = (projectList.matchingItems.length == 0);
		for (var i = 0, l = projectList.items.length; i < l; i++) {
			var thisItem = projectList.items[i];
			searchFilter[thisItem.values().pid] = (thisItem.matching());
		}
		p5.filterProjects();
	});	
}

function filterList(){
	for (var i = 0, l = projects.length; i < l; i++) {
		var xxx = projectList.items[i].values().pid;
		if (projects[xxx].active) projectList.items[i].show();
		else projectList.items[i].hide();
	}
}
function clearListSearch(elem) {
	if (projectList.matchingItems.length == 0) {
		elem.value='';
		projectList.search('');
	}
}

function localBoundingRect(elem) {
  var rectA = document.getElementById("content").getBoundingClientRect();
  var rectB = elem.getBoundingClientRect();
  var rh = rectB.height;
  var rw = rectB.width;
  var rl = rectB.left - rectA.left;
  var rb = rectB.bottom - rectA.top;
  var rt = rectB.top - rectA.top;
  var rr = rectB.right - rectA.left;
  var lbr = {height : rh, width : rw, left : rl, bottom : rb, top : rt, right : rr};
  return lbr;
}