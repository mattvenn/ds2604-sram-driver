import tweepy
import time
from secrets import *
from control import setup_ser, get_score

auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_secret)

api = tweepy.API(auth)

ser=setup_ser("/dev/ttyUSB1")

high_score = None

while True:
    score = get_score(ser)
    if high_score is None:
        high_score = score
        print("fetched new high score: %d" % high_score)
    
    if score != high_score:
        print("new high score: %d" % score)
        high_score = score
        message = "I got a new high score on Fire Power! %d" % score
        print(message)
        api.update_status('tweepy test')

    time.sleep(1)
