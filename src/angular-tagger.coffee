angular.module "tagger", []

# Angular 1.0.x polyfill for ng-keyup ng-keydown
# Stolen from https://github.com/angular/angular.js/blob/2bb27d4998805fd89db25192f53d26d259ae615f/src/ng/directive/ngEventDirs.js
for [directiveName, eventName] in [["ngKeydown", "keydown"], ["ngKeyup", "keyup"]]
  do (directiveName, eventName) ->
    angular.module("tagger").directive directiveName, ["$parse", ($parse) ->
      (scope, element, attr) ->
        fn = $parse(attr[directiveName])
        element.bind eventName, (event) ->
          scope.$apply -> fn(scope, {$event: event})
    ]

angular.module("tagger").directive "tagger", ["$compile", "$timeout", ($compile, $timeout) ->
  restrict: "AE"
  replace: true
  # priority: 0
  # terminal: true
  template: """
  <span class="angular-tagger">
    <span>
      <span ng-repeat="tag in tags">
        <input type="text"
          ng-model="$parent.query"
          ng-show="pos == $index"
          ng-keydown="handleKeyDown($event)"
          ng-keyup="handleKeyUp($event)"
          ng-click="handleInputClick($event)"
          class="angular-tagger_input" />
        <span class="angular-tagger_tag">
          {{ tag }}
          <span class="angular-tagger_tag_delete" ng-click="removeTag($index)">x</span>
        </span>
      </span>
    </span>
    <input type="text"
      ng-model="query"
      ng-show="pos == tags.length"
      ng-keydown="handleKeyDown($event)"
      ng-keyup="handleKeyUp($event)"
      ng-click="handleInputClick($event)"
      class="angular-tagger_input" />
    <ul ng-show="expanded" class="angular-tagger_matching">
      <li class="angular-tagger_matching_item_new"
        ng-mouseover="selectItem(-1)"
        ng-click="handleItemClick($event)"
        ng-class='{"angular-tagger_matching_item_selected": selected == -1}'>
        Add: {{ query }}...
      </li>
      <li
        ng-repeat="e in matching"
        ng-mouseover="selectItem($index)"
        ng-click="handleItemClick($event)"
        class="angular-tagger_matching_item"
        ng-class='{"angular-tagger_matching_item_selected": $index == selected}'>
        {{ e }}
      </li>
    </ul>
  </span>
  """
  scope:
    tags:     "=ngModel" # can't use ngModelController, we need isolated scope
    options:  "="


  link: ($scope, element, attrs) ->
    $scope.query = ""
    $scope.expanded = false
    $scope.matching = []
    $scope.selected = -1
    $scope.pos = $scope.tags.length

    input = element.children().eq(1)

    _updateMatching = () ->
      rx = new RegExp(".*#{$scope.query.split("").join(".*")}.*", "i")

      $scope.matching = []
      for opt in $scope.options
        if rx.test(opt)
          found = false
          for t in $scope.tags
            if t == opt
              found = true

          $scope.matching.push opt unless found

    _updateFocus = () ->
      # focusing on hidden element does not work
      $timeout ->
        _currentInput().focus()

    _currentInput = () ->
      return if $scope.pos == $scope.tags.length then input[0] else element.children().eq(0).children().eq($scope.pos).children()[0]

    $scope.handleKeyUp = ($event) ->
      switch $event.keyCode
        when 8 # Backspace
          _updateMatching()
        when 46 # Delete
          _updateMatching()
        when 27 # Escape
          $scope.hide()
        else
          if 65 < $event.keyCode < 90
            _updateMatching()
            $scope.show()
            $scope.selected = -1

    $scope.handleKeyDown = ($event) ->
      switch $event.keyCode
        when 38 # Up
          $scope.selected = Math.max($scope.selected - 1, -1)
          $event.preventDefault()
        when 40 # Down
          $scope.selected = Math.min($scope.selected + 1, $scope.matching.length - 1)
          $event.preventDefault()
        when 13 # Enter
          $scope.addItem()
        when 8 # Backspace
          if $scope.query == "" && $scope.pos > 0
            $scope.removeTag($scope.pos-1)
        when 46 # Delete
          if $scope.query == "" && $scope.pos < $scope.tags.length
            $scope.removeTag($scope.pos)
        when 37 # Left
          if $scope.query == ""
            $scope.pos = Math.max($scope.pos - 1, 0)
            _updateFocus()
        when 39 # Right
          if $scope.query == ""
            $scope.pos = Math.min($scope.pos + 1, $scope.tags.length)
            _updateFocus()

    $scope.handleInputClick = ($event) ->
      $event.stopPropagation()

    $scope.handleItemClick = ($event) ->
      $scope.addItem()
      $event.stopPropagation()


    $scope.addItem = () ->
      $scope.tags.splice $scope.pos, 0, ($scope.matching[$scope.selected] || $scope.query)
      $scope.query = ""
      _updateMatching()
      $scope.selected = Math.min($scope.selected, $scope.matching.length - 1)
      $scope.pos++
      _updateFocus()

    $scope.selectItem = (index) ->
      $scope.selected = index

    $scope.show = () ->
      $scope.expanded = true

    $scope.hide = () ->
      $scope.expanded = false
      _currentInput().blur()
      $scope.pos = $scope.tags.length

    $scope.removeTag = (pos) ->
      $scope.tags.splice(pos, 1)
      if pos < $scope.pos
        $scope.pos--
      _updateMatching()
      _updateFocus()

    angular.element(document).bind "click", (e) ->
      $scope.$apply -> $scope.hide()

    # bootstrap
    _updateMatching()

    input.bind "focus", ->
      $scope.$apply -> $scope.show()
]
