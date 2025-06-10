// import { Button } from '@/components/ui/button';
// import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
// import { Input } from '@/components/ui/input';
// import { Label } from '@/components/ui/label';
// import AppLayout from '@/layouts/app-layout';
// import { type BreadcrumbItem } from '@/types';
// import { Head } from '@inertiajs/react';

// const breadcrumbs: BreadcrumbItem[] = [
//     {
//         title: 'Add New Book',
//         href: '/books',
//     },
// ];

// export default function Index() {
//     return (
// <AppLayout breadcrumbs={breadcrumbs}>
//     <Head title="Add New Book" />
//             <div className="flex justify-center">
//                 <Card className="w-1/2">
//                     <CardHeader>
//                         <CardTitle>Add New Book</CardTitle>
//                         <CardDescription>Enter the details of your book below</CardDescription>
//                     </CardHeader>
//                     <CardContent>
//                         <form>
//                             <div className="flex flex-col gap-6">
//                                 <div className="grid gap-2">
//                                     <Label htmlFor="title">Title *</Label>
//                                     <Input id="title" type="title" placeholder="The Lord Of The Rings" required />
//                                 </div>
//                                 <div className="grid gap-2">
//                                     <Label htmlFor="author">Author *</Label>
//                                     <Input id="author" type="author" placeholder="J.R.R. Tolkien" required />
//                                 </div>
//                             </div>
//                         </form>
//                     </CardContent>
//                     <hr className="my-8 h-px border-0 bg-gray-200 dark:bg-gray-700"></hr>
//                     <CardFooter className="flex-col gap-2">
//                         <Button type="submit" className="w-max-sm hover:bg-sky-700">
//                             Add
//                         </Button>
//                     </CardFooter>
//                 </Card>
//             </div>
// </AppLayout>
//     );
// }

import { z } from 'zod';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import AppLayout from '@/layouts/app-layout';
import { BreadcrumbItem } from '@/types';
import { zodResolver } from '@hookform/resolvers/zod';
import { Head } from '@inertiajs/react';
import { Tooltip, TooltipContent, TooltipTrigger } from '@radix-ui/react-tooltip';
import axios from 'axios';
import { LucideCircleHelp } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';

//TODO no special characters allowed in title and author
//And no blanks
const formSchema = z.object({
    title: z.string().min(2, {
        message: 'Title must be at least 2 characters.',
    }),
    author: z.string().min(2, {
        message: 'Author must be at least 2 characters.',
    }),
});

const breadcrumbs: BreadcrumbItem[] = [
    {
        title: 'Add New Book',
        href: '/books',
    },
];

export default function Index() {
    const [users, setUsers] = useState([]);

    useEffect(() => {
        getUsers();
    }, []);

    const getUsers = () => {
        console.log('Fetching users...');
        axios.get('/users').then(({ data }) => {
            console.log('Users fetched successfully:', data);
            setUsers(data);
            console.log('Users state updated:', users);
        });
    };

    // 1. Define your form.
    const form = useForm<z.infer<typeof formSchema>>({
        resolver: zodResolver(formSchema),
        defaultValues: {
            title: '',
            author: '',
        },
    });

    // 2. Define a submit handler.
    const onSubmit = (ev) => {
        console.log('Fetching users...');
        axios.post('/users', users).then(({ data }) => {
            console.log('Users fetched successfully:', data);
            console.log('Users state updated:', users);
        });
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title="Add New Book" />
            <div className="flex justify-center">
                {users.map((user) => (
                    <div>{user.name}</div>
                ))}
                <Card className="w-1/2">
                    <CardHeader>
                        <CardTitle>Add New Book</CardTitle>
                        <CardDescription>Enter the details of your book below</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <Form {...form}>
                            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
                                <FormField
                                    control={form.control}
                                    name="title"
                                    render={({ field }) => (
                                        <FormItem>
                                            <Tooltip>
                                                <FormLabel>
                                                    Title *
                                                    <TooltipTrigger>
                                                        <LucideCircleHelp size={15} />
                                                    </TooltipTrigger>
                                                </FormLabel>
                                                <TooltipContent>
                                                    <p>This is the title of your book.</p>
                                                </TooltipContent>
                                            </Tooltip>
                                            <FormControl>
                                                <Input placeholder="The Lord Of The Rings" {...field} />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                                <FormField
                                    control={form.control}
                                    name="author"
                                    render={({ field }) => (
                                        <FormItem>
                                            <Tooltip>
                                                <FormLabel>
                                                    Author *
                                                    <TooltipTrigger>
                                                        <LucideCircleHelp size={15} />
                                                    </TooltipTrigger>
                                                </FormLabel>
                                                <TooltipContent>
                                                    <p>This is the author of your book.</p>
                                                </TooltipContent>
                                            </Tooltip>
                                            <FormControl>
                                                <Input placeholder="J.R.R. Tolkien" {...field} />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                                <hr className="my-8 h-px border-0 bg-gray-200 dark:bg-gray-700"></hr>
                                <Button type="submit" className="w-max-sm hover:bg-sky-700">
                                    Add
                                </Button>
                            </form>
                        </Form>
                    </CardContent>
                </Card>
            </div>
        </AppLayout>
    );
}
