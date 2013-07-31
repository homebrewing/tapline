passport = require 'passport'

authController = module.exports

authController.loginPage = (req, res) ->
    res.render 'login',
        next: req.query.next

authController.login = (method) ->
    (req, res, next) ->
        passport.authenticate(method,
            successRedirect: req.body.next or '/account'
            failureRedirect: '/account/login'
        )(req, res, next)

authController.logout = (req, res) ->
    req.logout()
    res.redirect('/account/login')
