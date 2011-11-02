$(document).ready( ->
  module("knockback.js with Backbone.ModelRef.js")
  test("TEST DEPENDENCY MISSING", ->
    ko.utils; _.VERSION; Backbone.VERSION
  )

  Knockback.locale_manager = new LocaleManager('en', {
    'en': {loading: "Loading dude"}
    'en-GB': {loading: "Loading sir"}
    'fr-FR': {loading: "Chargement"}
  })

  test("Standard use case: just enough to get the picture", ->
    class ContactViewModel
      constructor: (model) ->
        @loading_message = new LocalizedObservable_LocalizedString(new LocalizedString('loading'))
        @attribute_observables = new kb.ModelAttributeObservables(model, {
          name:     {keypath:'name', default: @loading_message}
          number:   {keypath:'number', write: true, default: @loading_message}
          date:     {keypath:'date', write: true, default: @loading_message, localizer: (value) => return new LocalizedObservable_LongDate(value)}
        }, this)
      destroy: ->
        @attribute_observables.destroy()

    collection = new ContactsCollection()
    model_ref = new Backbone.ModelRef(collection, 'b4')
    view_model = new ContactViewModel(model_ref)

    Knockback.locale_manager.setLocale('en')
    equal(view_model.name(), 'Loading dude', "Is that what we want to convey?")
    Knockback.locale_manager.setLocale('en-GB')
    equal(view_model.name(), 'Loading sir', "Maybe too formal")
    Knockback.locale_manager.setLocale('fr-FR')
    equal(view_model.name(), 'Chargement', "Localize from day one. Good!")

    collection.add(collection.parse({id: 'b4', name: 'John', number: '555-555-5558', date: new Date(1940, 10, 9)}))
    model = collection.get('b4')

    # get
    equal(view_model.name(), 'John', "It is a name")
    equal(view_model.number(), '555-555-5558', "Not so interesting number")
    Knockback.locale_manager.setLocale('en-GB')
    equal(view_model.date(), '09 November 1940', "John's birthdate in Great Britain format")
    Knockback.locale_manager.setLocale('fr-FR')
    equal(view_model.date(), '09 novembre 1940', "John's birthdate in France format")

    # set from the view model
    raises((->view_model.name('Paul')), null, "Cannot write a value to a dependentObservable unless you specify a 'write' option. If you wish to read the current value, don't pass any parameters.")
    equal(model.get('name'), 'John', "Name not changed")
    equal(view_model.name(), 'John', "Name not changed")
    view_model.number('9222-222-222')
    equal(model.get('number'), '9222-222-222', "Number was changed")
    equal(view_model.number(), '9222-222-222', "Number was changed")
    Knockback.locale_manager.setLocale('en-GB')
    view_model.date('10 December 1963')
    current_date = model.get('date')
    equal(current_date.getFullYear(), 1963, "year is good")
    equal(current_date.getMonth(), 11, "month is good")
    equal(current_date.getDate(), 10, "day is good")

    # set from the model
    model.set({name: 'Yoko', number: '818-818-8181'})
    equal(view_model.name(), 'Yoko', "Name changed")
    equal(view_model.number(), '818-818-8181', "Number was changed")
    model.set({date: new Date(1940, 10, 9)})
    Knockback.locale_manager.setLocale('fr-FR')
    equal(view_model.date(), '09 novembre 1940', "John's birthdate in France format")
    view_model.date('10 novembre 1940')
    current_date = model.get('date')
    equal(current_date.getFullYear(), 1940, "year is good")
    equal(current_date.getMonth(), 10, "month is good")
    equal(current_date.getDate(), 10, "day is good")

    # go back to loading state
    collection.reset()
    equal(view_model.name(), 'Yoko', "Default is to retain the last value")
    view_model.name.forceRefresh() # override default behavior and go back to loading state
    Knockback.locale_manager.setLocale('en')
    equal(view_model.name(), 'Loading dude', "Is that what we want to convey?")
    Knockback.locale_manager.setLocale('en-GB')
    equal(view_model.name(), 'Loading sir', "Maybe too formal")
    Knockback.locale_manager.setLocale('fr-FR')
    equal(view_model.name(), 'Chargement', "Localize from day one. Good!")
  )
)