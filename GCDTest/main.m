//
//  main.m
//  GCDTest
//
//  Created by song on 12-11-18.
//  Copyright (c) 2012年 Zero. All rights reserved.
//

#import <Foundation/Foundation.h>
static const char *const MY_QUEUE_LABEL1 = "me.songzhipeng.my_queue_label1";
static const char *const MY_QUEUE_LABEL2 = "me.songzhipeng.my_queue_label2";

#define ThreadName() ([NSThread isMainThread]?@"MainThread":@"SubThread")

#define customQueue		dispatch_queue_create(MY_QUEUE_LABEL2, NULL)
#define defaultQueue 	dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define highQueue 		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
#define lowQueue 		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)

int num = 0;

inline void printNum(int n);
void printNum(int n) {
	for (int i=0; i<100; i++) {
		printf("%d",n);
	}
}

void testGCD4() {
	dispatch_queue_t aDQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    // Add a task to the group
    dispatch_group_async(group, aDQueue, ^{
        printf("task 1 \n");
    });
    dispatch_group_async(group, aDQueue, ^{
        printf("task 2 \n");
    });
    dispatch_group_async(group, aDQueue, ^{
        printf("task 3 \n");
    });
    printf("wait 1 2 3 \n");
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    printf("task 1 2 3 finished \n");
    dispatch_release(group);
    group = dispatch_group_create();
    // Add a task to the group
    dispatch_group_async(group, aDQueue, ^{
        printf("task 4 \n");
    });
    dispatch_group_async(group, aDQueue, ^{
        printf("task 5 \n");
    });
    dispatch_group_async(group, aDQueue, ^{
        printf("task 6 \n");
    });
    printf("wait 4 5 6 \n");
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    printf("task 4 5 6 finished \n");
    dispatch_release(group);
}

void testGCD2() {
	dispatch_async(highQueue, ^{
		printNum(3);
	});
	dispatch_async(defaultQueue, ^{
		printNum(1);
	});
	dispatch_async(defaultQueue, ^{
		printNum(2);
	});
}

void testGCD3() {
	//SubThread1
	dispatch_async(defaultQueue, ^{
		NSLog(@"default1:%@",ThreadName());
	});
	
	//SubThread2
	dispatch_async(defaultQueue, ^{
		NSLog(@"default2:%@",ThreadName());
	});
	
	//SubThread3
	dispatch_async(highQueue, ^{
		NSLog(@"high1:%@",ThreadName());
	});
	
	//SubThread4
	dispatch_async(highQueue, ^{
		NSLog(@"high2:%@",ThreadName());
	});
	
	//每一个都是不同的线程
	dispatch_queue_t myQueue = dispatch_queue_create(MY_QUEUE_LABEL1, NULL);
	for (int i=0; i<100; i++) {
		dispatch_async(myQueue, ^{
			NSLog(@"custom%d:%@",i,ThreadName());
		});
	}
	
	/*
	 *	结论：
	 *	系统给定的三个优先级队列（global的原因？）是不同的线程，自定义的也是
	 */
}

void testGCD1() {
	dispatch_queue_t waitQueue = dispatch_queue_create("wait_queue", NULL);
	dispatch_suspend(waitQueue);
	dispatch_suspend(waitQueue);
	dispatch_sync(customQueue, ^{
		// 创建一个用户队列
        // 用户队列FIFO
		dispatch_queue_t myQueue =dispatch_queue_create(MY_QUEUE_LABEL1, NULL);
		// 同步执行代码块
		// 相当于waitUntil:YES
		// 运行在当前线程——主线程中
		dispatch_sync(myQueue, ^{
			for (int i=0; i<3; i++) {
				NSLog(@"%@:%d",ThreadName(),num++);
				[NSThread sleepForTimeInterval:.3];
			}
		});
		
		// 暂停队列，暂停计数+1
		dispatch_suspend(myQueue);
		NSLog(@"*****suspend*****");
		
		[NSThread sleepForTimeInterval:1.];
		
		// 异步执行代码块1
		// 相当于waitUntil:NO
		// 运行在子线程中
		// 此时“暂停计数”==1，>0，代码块挂起
		dispatch_async(myQueue, ^{
			for (int i=0; i<10; i++) {
				NSLog(@"++1++%@:%d",ThreadName(),num++);
			}
			dispatch_resume(waitQueue);
		});
		
		// 异步执行代码块2
		//TODO: 为什么要等代码块1执行完毕才执行呢？难道不能并发？
		dispatch_async(myQueue, ^{
			for (int i=0; i<10; i++) {
				NSLog(@"++2++%@:%d",ThreadName(),num++);
			}
			dispatch_resume(waitQueue);
		});
		
		// 继续队列，暂停计数-1
		// 此时“暂停计数”==0，上面的异步代码块被执行
		dispatch_resume(myQueue);
		NSLog(@"*****resume*****");
	});
	dispatch_sync(waitQueue, ^{
	});
}

void testGCD6() {
	dispatch_queue_t myQueue = dispatch_queue_create(MY_QUEUE_LABEL1, NULL);
	dispatch_group_t myGroup = dispatch_group_create();
	dispatch_group_async(myGroup, myQueue, ^{
		printNum(1);
	});
    dispatch_group_async(myGroup, myQueue, ^{
		printNum(4);
	});
    dispatch_group_async(myGroup, myQueue, ^{
		printNum(7);
	});
    dispatch_group_async(myGroup, defaultQueue, ^{
		printNum(8);
	});
    dispatch_group_async(myGroup, defaultQueue, ^{
		printNum(9);
	});
	
    NSLog(@"wait group1 finishing");
	dispatch_group_wait(myGroup, DISPATCH_TIME_FOREVER);
	dispatch_release(myGroup);
    
    NSLog(@"first group1 finished");
    
    
	myGroup = dispatch_group_create();
	
	dispatch_group_async(myGroup, defaultQueue, ^{
		printNum(2);
	});
	
	dispatch_group_async(myGroup, defaultQueue, ^{
		printNum(3);
	});
	
    NSLog(@"waiting group finishing");
	dispatch_group_wait(myGroup, DISPATCH_TIME_FOREVER);
    
    NSLog(@"second group finished");
}

void myFinalizerFunction(void *context) {
	NSLog(@"final function");
	NSLog(@"context:%@",(id)context);
}

void testGCD7() {
	dispatch_queue_t serialQueue = customQueue;
	NSArray *context = @[@1,@2];
    if (serialQueue)
    {
        dispatch_set_context(serialQueue, context);
		dispatch_function_t finalFunc = &myFinalizerFunction;
        dispatch_set_finalizer_f(serialQueue, finalFunc);
    }
    
    dispatch_group_t group = dispatch_group_create();
    
    // Add a task to the group
    dispatch_group_async(group, serialQueue, ^{
		NSLog(@"task 1");
    });
    
    dispatch_group_async(group, serialQueue, ^{
        NSLog(@"task 2");
    });
    
    dispatch_group_async(group, serialQueue, ^{
		NSLog(@"task 3");
    });
	NSLog(@"wait 1 2 3");
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    dispatch_release(group);
    dispatch_release(serialQueue);
}

void testGCD8()
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(4);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (int i = 0; i < 100; i++)
    {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_group_async(group, queue, ^{
        NSLog(@"%i",i);
        sleep(2);
        dispatch_semaphore_signal(semaphore);
        });
    }
    
    
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    dispatch_release(group);
    dispatch_release(semaphore);
}

void testGCD9()
{
    if (dispatch_get_main_queue()) {
        NSLog(@"aaaa");
    }
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(4);
    
    //dispatch_queue_t myQueue = dispatch_queue_create(MY_QUEUE_LABEL1, NULL);
    dispatch_group_t myGroup = dispatch_group_create();
    
    dispatch_group_async(myGroup, highQueue,^(void){
        
		for (int i = 0; i < 100; i++){
            //NSLog(@"****progress=%d****",i);
			sleep(2);
            NSLog(@"****beginprogress=%d****",i);
			
            
            dispatch_semaphore_signal(sem);
		}
        
        //dispatch_semaphore_signal(sem);
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //update UI
           
            NSLog(@"----progress=****");
        });
        
        //dispatch_semaphore_signal(sem);
		
    });

   
	dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    NSLog(@"Finished!");
    dispatch_group_wait(myGroup, DISPATCH_TIME_FOREVER);
    dispatch_release(myGroup);
    NSLog(@"group Finished!");
        
        

}

void testGCD10()
{
    
    //dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_queue_t myQueue = dispatch_queue_create(MY_QUEUE_LABEL1, NULL);
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_async(myQueue, ^{
        for (int i=0; i<100000; i++) {
            NSLog(@"%d",i);
        }
        
        //主线程退出不进行任何输出
        dispatch_async(queue, ^{
            NSLog(@"finished");
        });
    });
    
    //dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    NSLog(@"111");
    //主线程退出
    //sleep(2);
}

int main(int argc, const char * argv[])
{
	@autoreleasepool {
	    testGCD9();
	}
	[NSThread sleepForTimeInterval:1.];
    return 0;
}

