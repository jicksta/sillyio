Sillyio
=======

Because Twilio is silly.

Better README coming soon.

Gripes
------
* Why do verbs such as Play and Say have loop attribute? Why not have a Loop verb and nest any element within it?

TODO
------
* Put in place several events.rb hooks
* Automatically upload recordings to S3
* See if DNIS works for the "Called" property.
* AMD
Notes
-----
I'm almost certain Twilio uses Asterisk behind the scenes. Things such as <Dial>'s hangupOnStar and <Number>'s sendDigits are a dead giveaway.



<code>
<?xml version="1.0" encoding="UTF-8"?>  
<Response>  
    <Dial>  
        <Number>  
            858-987-6543  
        </Number>  
        <Number>  
            415-123-4567  
        </Number>  
        <Number>  
            619-765-4321  
        </Number>  
    </Dial>  
</Response> 
</code>