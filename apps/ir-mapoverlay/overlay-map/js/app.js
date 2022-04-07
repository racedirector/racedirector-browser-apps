const app = angular.module("overlay-map", [
  "ngRoute",
  "mgcrea.ngStrap.navbar",
  "LocalStorageModule",
  "kutu.markdown",
  "colorpicker.module",
]);

app.config(($routeProvider) =>
  $routeProvider
    .when("/", { templateUrl: "tmpl/index.html" })
    .when("/settings", {
      templateUrl: "tmpl/settings.html",
      controller: "SettingsCtrl",
      title: "Settings",
    })
    .otherwise({ redirectTo: "/" })
);

app.config((localStorageServiceProvider) =>
  localStorageServiceProvider.setPrefix(app.name)
);

app.run(($rootScope, $sce) =>
  $rootScope.$on("$routeChangeSuccess", function (event, current, previous) {
    let title = "Track Map Overlay &middot; iRacing Browser Apps";
    if (current.$$route.title != null) {
      title = current.$$route.title + " &middot; " + title;
    }
    return ($rootScope.title = $sce.trustAsHtml(title));
  })
);

app.controller("SettingsCtrl", function ($scope, localStorageService) {
  let sanitizeDriverGroups, saveSettings, settings, trimComma;
  const defaultSettings = {
    host: "localhost:8182",
    fps: 30,
    trackColor: "#000000",
    trackWidth: 10,
    trackOutlineColor: "#FFFFFF",
    trackAlignment: "center",
    startFinishColor: "#FF0000",
    sectorColor: "#FFDA59",
    showSectors: false,
    driverCircle: 12,
    circleColor: "",
    driverHighlightWidth: 4,
    driverHighlightCam: "#4DFF51",
    driverHighlightOfftrack: "#FF0000",
    driverPosNum: "#000000",
    highlightNum: "#FFFFFF",
    playerHighlight: "",
    driverGroups: [],
  };

  $scope.isDefaultHost = document.location.host === defaultSettings.host;

  $scope.settings = settings = localStorageService.get("settings") || {};
  settings.host = settings.host || null;
  settings.fps = settings.fps || defaultSettings.fps;
  settings.trackColor = settings.trackColor || defaultSettings.trackColor;
  settings.trackWidth = settings.trackWidth || defaultSettings.trackWidth;
  settings.trackOutlineColor =
    settings.trackOutlineColor || defaultSettings.trackOutlineColor;
  settings.trackAlignment =
    settings.trackAlignment || defaultSettings.trackAlignment;
  settings.startFinishColor =
    settings.startFinishColor || defaultSettings.startFinishColor;
  settings.sectorColor = settings.sectorColor || defaultSettings.sectorColor;
  settings.showSectors = settings.showSectors || defaultSettings.showSectors;
  settings.driverCircle = settings.driverCircle || defaultSettings.driverCircle;
  settings.circleColor = settings.circleColor || defaultSettings.circleColor;
  settings.driverHighlightWidth =
    settings.driverHighlightWidth || defaultSettings.driverHighlightWidth;
  settings.driverHighlightCam =
    settings.driverHighlightCam || defaultSettings.driverHighlightCam;
  settings.driverHighlightOfftrack =
    settings.driverHighlightOfftrack || defaultSettings.driverHighlightOfftrack;
  settings.driverPosNum = settings.driverPosNum || defaultSettings.driverPosNum;
  settings.highlightNum = settings.highlightNum || defaultSettings.highlightNum;
  settings.playerHighlight =
    settings.playerHighlight || defaultSettings.playerHighlight;
  settings.driverGroups = settings.driverGroups || defaultSettings.driverGroups;

  $scope.saveSettings = saveSettings = function () {
    settings.fps = Math.min(60, Math.max(1, settings.fps));
    localStorageService.set("settings", settings);
    return updateURL();
  };

  const actualKeys = [
    "host",
    "fps",
    "trackColor",
    "trackWidth",
    "trackOutlineColor",
    "trackAlignment",
    "startFinishColor",
    "sectorColor",
    "showSectors",
    "driverCircle",
    "circleColor",
    "driverHighlightWidth",
    "driverHighlightCam",
    "driverHighlightOfftrack",
    "driverPosNum",
    "highlightNum",
    "playerHighlight",
  ];

  var updateURL = function () {
    const params = [];
    for (let k in settings) {
      const v = settings[k];
      if (k in defaultSettings && v === defaultSettings[k]) {
        continue;
      }
      if (k === "host" && (!settings.host || $scope.isDefaultHost)) {
        continue;
      }
      if (actualKeys.includes(k)) {
        params.push(`${k}=${encodeURIComponent(v)}`);
      }
      if (k === "driverGroups") {
        for (let group of v) {
          if (group.ids === "" || group.color === "") {
            continue;
          }
          params.push(`dGrp=${encodeURIComponent(group.ids)}`);
          params.push(`dGrpClr=${encodeURIComponent(group.color)}`);
        }
      }
    }

    return ($scope.url = `http://${
      document.location.host
    }/ir-mapoverlay/overlay-map/overlay.html\
${params.length ? "#?" + params.join("&") : ""}`);
  };
  updateURL();

  $scope.changeURL = function () {
    const params =
      $scope.url &&
      $scope.url.search("#?") !== -1 &&
      $scope.url.split("#?", 2)[1];
    if (!params) {
      return;
    }

    const parts = $scope.url.split("#?", 2)[1].split("&");
    for (let p of parts) {
      let [k, v] = p.split("=", 2);
      if (!(k in settings)) {
        continue;
      }
      const nv = Number(v);
      if (!isNaN(nv && v.length === nv.toString().length)) {
        v = Number(v);
      }
      settings[k] = v;
    }
    return saveSettings();
  };

  $scope.sanitizeDriverGroups = sanitizeDriverGroups = function () {
    for (let group of settings.driverGroups) {
      group.ids = group.ids.replace(/,{2,}/g, ",");
      group.ids = group.ids.replace(/[^0-9,]/g, "");
    }
    return saveSettings();
  };

  $scope.trimComma = trimComma = function () {
    for (let group of settings.driverGroups) {
      if (group.ids.charAt(group.ids.length - 1) === ",") {
        group.ids = group.ids.slice(0, -1);
      }
    }
    return saveSettings();
  };

  $scope.addGroup = () => settings.driverGroups.push({ ids: "", color: "" });

  return ($scope.removeGroup = function (element) {
    settings.driverGroups.splice(this.$index, 1);
    return saveSettings();
  });
});

angular.bootstrap(document, [app.name]);
