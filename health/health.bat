@REM Create a schedule task to remind me of taking care of my health on windows
schtasks /create /tn health /tr "msg alpha 'Have a rest, drink water, relax your eyes!'" /sc hourly /st 08:00