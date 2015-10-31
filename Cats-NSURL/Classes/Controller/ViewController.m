//
//  ViewController.m
//  Cats-NSURL
//
//  Created by Admin on 27.10.15.
//  Copyright (c) 2015 OlhaF. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView * catImageView;
@property (weak, nonatomic) IBOutlet UIView * pleaseWait;
@property (weak, nonatomic) IBOutlet UILabel * lableURL;
@property (weak, nonatomic) IBOutlet UIButton * kittyButton;
@property (weak, nonatomic) IBOutlet UIButton * logButton;

@property (strong, nonatomic) NSDictionary * jsonDictionary;

@end

@implementation ViewController

#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.kittyButton.layer.borderWidth = 1.0f;
    self.kittyButton.layer.borderColor = [[UIColor blueColor] CGColor];
    self.kittyButton.layer.cornerRadius = 8.0f;
    
    self.logButton.layer.borderWidth = 1.0f;
    self.logButton.layer.borderColor = [[UIColor blueColor] CGColor];
    self.logButton.layer.cornerRadius = 8.0f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button actions
- (IBAction) downloadImageAction:(UIButton*)sender
{
    sender.enabled = NO;
    self.pleaseWait.hidden = NO;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [self getDataForRandomCatPhoto];
}

- (IBAction) postImageAction:(UIButton*)sender
{
    sender.enabled = NO;
    self.pleaseWait.hidden = NO;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [self uploadCatPhoto];
}

#pragma mark - Download methods
- (void) getDataForRandomCatPhoto
{
    NSURL * resourseURL = [NSURL URLWithString:@"http://random.cat/meow"];
    
    NSURLSession * session = [NSURLSession sessionWithConfiguration: [self getSessionConfiguration]];
    
    //get URL for random cat photo
    NSURLSessionTask * getDataForURLTask = [session dataTaskWithURL:resourseURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if ([response respondsToSelector:@selector(statusCode)])
        {
            if ([(NSHTTPURLResponse *) response statusCode] == 200)
            {
                [self createDictionaryFromData:data];
                
                if (self.jsonDictionary)
                {
                    [self downloadCatPhoto];
                }
            }
        }
    }];
    
    [getDataForURLTask resume];
}

- (void) downloadCatPhoto
{
    NSURL * catURL = [[NSURL alloc] initWithString:[self.jsonDictionary objectForKey:@"file"]];
    NSURLSession * session = [NSURLSession sessionWithConfiguration: [self getSessionConfiguration]];
    
    NSURLSessionDownloadTask * downloadImageTask = [session downloadTaskWithURL:catURL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        
        UIImage * downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];

            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                self.pleaseWait.hidden = YES;
                
                if (downloadedImage)
                {
                    self.catImageView.image = downloadedImage;
                }
                else
                {
                    self.lableURL.text = @"Error - Photo downloading failed";
                }
                self.kittyButton.enabled = YES;
            });
    }];
    
    [downloadImageTask resume];
}

#pragma mark - Upload methods

- (void) uploadCatPhoto
{
   NSURLSessionConfiguration *configuration = [self getUploadSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURL *url = [NSURL URLWithString:@"https://api.parse.com/1/classes/Logs"];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";

    NSError *error = nil;
    NSString * catURL = [self.jsonDictionary objectForKey:@"file"];
    NSMutableDictionary * postDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      @"OlhaMC",@"userID",catURL,@"catURL",nil];
    NSData * catReference = [NSJSONSerialization dataWithJSONObject:postDict options:kNilOptions error:&error];
    
    if (!error) {
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
        fromData:catReference completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
          if ([response respondsToSelector:@selector(statusCode)])
          {
              dispatch_async(dispatch_get_main_queue(), ^{
                  
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                self.pleaseWait.hidden = YES;
                  
                if ([(NSHTTPURLResponse *) response statusCode] == 201 || [(NSHTTPURLResponse *) response statusCode] == 200)
                   self.lableURL.text = @"Photo uploaded to - https://api.parse.com/1/classes/Logs";
                else
                    self.lableURL.text = @"Error - Photo uploading failed";
                  
                self.logButton.enabled = YES;
              });
           }
          //NSLog(@"response - %@", response);
       }];
       [uploadTask resume];
    }
}


#pragma mark - additional methods
- (NSURLSessionConfiguration *) getSessionConfiguration
{
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 30.0f;
    configuration.timeoutIntervalForResource = 60.0f;
    return configuration;
}

- (NSURLSessionConfiguration *) getUploadSessionConfiguration
{
    NSURLSessionConfiguration * configuration = [self getSessionConfiguration];
    
    [configuration setHTTPAdditionalHeaders:
     @{@"X-Parse-Application-Id":@"wGuKBRFghDRy3K2JuL9IkCwBssmQ2K0qR2noI5Qx",
       @"X-Parse-REST-API-Key":@"qlAavQKuwnUeCl2L1FcCPUfMMkHJPL75cJjDLsQb",
       @"Content-Type": @"json"}];
    
    return  configuration;
}

- (void) createDictionaryFromData: (NSData*) data
{
    NSError *parseJsonError = nil;
    
    NSDictionary *jsonDict =
    [NSJSONSerialization JSONObjectWithData:data
                                    options:NSJSONReadingAllowFragments
                                      error:&parseJsonError];
    if (!parseJsonError)
    {
        self.jsonDictionary = jsonDict;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.lableURL.text = jsonDict[@"file"];
        });
        //NSLog(@"json data = %@", jsonDict);
    }
}


@end
